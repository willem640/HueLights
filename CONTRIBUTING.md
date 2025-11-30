## Adding a new light integration
The first step is to create a new JavaScript file defining your integration. A light integration should provide an update function like this one:
```js
// yourIntegration.js
getYourIntegrationData(pluginData, completionHandler) {
    // the completion handler is to be called when the data is ready

    // for example:
    const yourRooms = getYourData();

    completionHandler(yourRooms);

    // or:

    Proc.runCommand(
        "hueLights.yourIntegration.fetchData",
        ["curl", "-s", "https://api.example.com/data"],
        (stdout, exitCode) => {
            if (exitCode === 0) {
                const yourRooms = processData(stdout);
                completionHandler(yourRooms);
            } else {
                console.error("Could not fetch yourIntegration data: command failed with exit code:", exitCode);
            }
        },
        100
    )
}
```

The rooms should be conform to the following schema. They may have extra properties, like the guid that's used to control the lights and scenes in the Philips Hue integration. If the integration works purely by light names, you might need to track the owning room's name in each light and scene.

If a room or light does not support color, color temperature, etc., simply leave the property and/or setter undefined. The rooms and lights will need to have at least:
- a name
- an id
- an icon.
The rest is purely optional. The UI will show, hide or disable the relevant toggle or slider depending on what you provide.
```js
const yourRooms = [
    {
        name: "Living room",
        id: "2d3cf504-96c8-471b-b1ae-f51417eb9328", // a unique ID used when updating the rooms. Should be unique for each room and consistent across data refreshes
        iconName: "chair", // May be derived from the API, like in the Hue integration. Any Material icon name
        on: true,
        brightness: 75, // may be the average brightness for the room, [0,100]
        colorTemperature: 0.7, // The rooms current color temperature, where 0 is the most warm and 1 is the most cold [0,1]
        color: "#ccab2b",
        turnOnOff(on) {
            // call function to turn all the room's lights on or off
        },
        setBrightness(brightness) {
            // for example:
            yourIntegrationSetRoomBrightNess(this, brightness);
        },
        setColorTemperature(ratio) {
            // set color temperature
        },

        lights: [ 
            {
                name: "Veranda light",
                iconName: "lightbulb_2", // Material icon name
                id: "4f4fa34e-84c8-40ca-a8a3-5f8d8a3f579b",
                brightness: 80,
                on: true,
                colorTemperature: 0.7, // The lights current color temperature, where 0 is the most warm and 1 is the most cold [0,1]
                color: "#ccab2b",
                turnOnOff(on) {
                    // call function to turn light on/off
                },
                setBrightness(value) {
                    // set brightness
                }
            }
        ],
        scenes: [
            {
                name: "Evening",
                enable() {
                    // enable the scene
                }
            }
        ]
    }
]
```

When the integration is ready to test, add a setting for it in the PluginSettings:
```qml
// HueLightsSettings.qml
ToggleSetting {
    settingKey: "yourIntegration:enable"
    label: "Your Integration's name."
    description: "Enable Hue Lights through your integration."
    defaultValue: true
}
```

If needed, you may add a StyledRect with additional configuration options like the one for Hue Lights through openhue-cli.

When the setting has been added, import your integration's JavaScript file in `HueLightsWidget.qml`, and add it to the update function:

```qml
    // HueLightsWidget.qml
    // ...
    import "YourIntegration.js" as YourIntegration

    // ...

    var services = {
        // ...
        // "your integration's setting toggle": your integration's update endpoint
        "yourintegration: enable": YourIntegration.getYourIntegrationData,
    }

    // Note: in v0.0.1, settings aren't working yet, so you'll need to add it to the updateFunctions array manually:
    var updateFunctions = [
        // ...
        YourIntegration.getYourIntegrationData
    ]

```
