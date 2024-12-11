return table.freeze({
    FF = {
        TEAM_SWITCH_DELAY = 0.3,
        POSITION_UPDATE_INTERVAL = 0.1,
        MAX_ATTEMPTS = 3,
        TEAMS = {
            ORANGE = "Bright orange",
            BLUE = "Bright blue"
        }
    },
    KILL = {
        INTERVAL = 0.03,
        OFFSET = Vector3.new(0, 0, -2),
        MAX_TARGETS = 10,
        MAX_ATTEMPTS = 10,
        RETRY_DELAY = 0,
        FF_WAIT = 3
    },
    AURA = {
        RADIUS = 15,
        CHECK_INTERVAL = 0.03
    },
    INVIS = {
        PLATFORM_HEIGHT = 10000,
        TELEPORT_DELAY = 0.25,
        PLATFORM_SIZE = Vector3.new(10, 1, 10)
    },
    DEBUG = true,
    COMMANDS = {
        "/cmds - Show all commands",
        "/ff - Enable forcefield",
        "/unff - Disable forcefield",
        "/kill [player/others/team] - Kill specific player, all others, or team",
        "/aura - Enable kill aura",
        "/noaura - Disable kill aura",
        "/invis - Enable invisibility",
        "/visible - Disable invisibility",
        "/view [name] - View player",
        "/unview - Return to own view",
        "/goto [player] - Teleport to player"
    }
})