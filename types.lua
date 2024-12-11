type StateType = {
    ff: {
        enabled: boolean,
        changingTeam: boolean,
        lastPosition: Vector3?,
        lastOrientation: CFrame?,
        lastUpdate: number
    },
    kill: {
        enabled: boolean,
        mainLoop: thread?
    },
    aura: {
        enabled: boolean,
        mainLoop: thread?
    },
    invis: {
        enabled: boolean,
        platform: Part?,
        savedPosition: Vector3?
    },
    view: {
        enabled: boolean,
        target: Player?,
        originalSubject: Instance?
    }
}

return StateType