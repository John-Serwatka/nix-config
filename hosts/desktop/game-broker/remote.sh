# game-broker-remote — forced command for core's broker key (broker-control).
#
# sshd ignores whatever core asked to run and runs this instead, with the
# request in $SSH_ORIGINAL_COMMAND. It is parsed here and nowhere else; it is
# never handed to a shell. Protocol v1: one JSON object on stdout, always.
#
# Stage 3: `status` only, read-only. start/stop come with Stage 4.

agent_version="0.3.0"
protocol='{"major":1,"minor":0}'
capabilities='["status"]'

# Every response carries the envelope; $1 is the verb-specific body.
respond() {
  jq -cn \
    --arg agent_version "$agent_version" \
    --argjson protocol "$protocol" \
    --argjson capabilities "$capabilities" \
    --argjson body "$1" \
    '{agent_version: $agent_version, protocol: $protocol, capabilities: $capabilities} + $body'
}

reject() {
  respond "$(jq -cn --arg reason "$1" '{ok: false, reason: $reason}')"
  exit 1
}

# One logind session as JSON. Fails (non-zero) if the session vanished or
# logind did not answer — the caller treats that as `unknown`.
session_json() {
  local props
  props="$(loginctl show-session "$1" \
    -p Id -p Name -p Class -p Type -p Service -p State -p Remote -p VTNr)" || return 1
  jq -cRn --arg self "${XDG_SESSION_ID:-}" '
    [inputs | capture("^(?<key>[^=]+)=(?<value>.*)$")] | from_entries
    | {id: .Id, user: .Name, class: .Class, type: .Type, service: .Service,
       state: .State, remote: (.Remote == "yes"), vt: (.VTNr | tonumber? // null),
       self: (.Id == $self)}' <<<"$props"
}

# Whether withrin has a process with this exact name. pgrep exits 1 for "no
# match"; anything above that is a failed query.
user_has_process() {
  local rc=0
  pgrep -u withrin -x "$1" >/dev/null || rc=$?
  case "$rc" in
    0) echo true ;;
    1) echo false ;;
    *) return 1 ;;
  esac
}

status() {
  local ok=true ids id sessions="[]" s steam=null sunshine=null dm boot_id state_file=false

  boot_id="$(cat /proc/sys/kernel/random/boot_id)"
  dm="$(systemctl is-active display-manager.service || true)"
  [ -e /run/game-broker/state.json ] && state_file=true

  if ids="$(loginctl list-sessions --json=short | jq -r '.[].session')"; then
    for id in $ids; do
      if s="$(session_json "$id")"; then
        sessions="$(jq -c --argjson s "$s" '. + [$s]' <<<"$sessions")"
      else
        ok=false
      fi
    done
  else
    ok=false
  fi

  steam="$(user_has_process steam)" || ok=false
  sunshine="$(user_has_process sunshine)" || ok=false

  # Ownership, from the design's definitions:
  #   unknown       any query failed
  #   inconsistent  broker evidence (a state file or a Service=game-broker
  #                 session). Stage 3 has no broker, so any evidence of one
  #                 is by definition a piece that does not fit; Stage 4 adds
  #                 the fully-agreeing `broker` case.
  #   local         a graphical user session not started by the broker, in
  #                 ANY state including `closing`
  #   inconsistent  no session, but withrin's steam/sunshine still running
  #   none          otherwise
  respond "$(jq -cn \
    --argjson ok "$ok" \
    --argjson sessions "$sessions" \
    --argjson steam "${steam:-null}" \
    --argjson sunshine "${sunshine:-null}" \
    --argjson state_file "$state_file" \
    --arg boot_id "$boot_id" \
    --arg dm "$dm" '
    ($sessions | map(select(.class == "user" and (.type == "x11" or .type == "wayland")))) as $graphical
    | ($state_file or ($sessions | any(.service == "game-broker"))) as $broker_evidence
    | {
        ok: true,
        verb: "status",
        boot_id: $boot_id,
        ownership: (
          if $ok | not then "unknown"
          elif $broker_evidence then "inconsistent"
          elif ($graphical | map(select(.service != "game-broker")) | length) > 0 then "local"
          elif $steam or $sunshine then "inconsistent"
          else "none" end),
        display_manager: $dm,
        greeter_present: ($sessions | any(.class == "greeter")),
        sessions: $sessions,
        user_processes: {steam: $steam, sunshine: $sunshine},
        streams: {value: null, source: "unsupported"}
      }')"
}

command="${SSH_ORIGINAL_COMMAND:-}"
read -r -a argv <<<"$command" || true
case "${argv[0]:-}" in
  status)
    [ "$command" = "status" ] || reject invalid_argument
    status
    ;;
  *) reject unknown_verb ;;
esac
