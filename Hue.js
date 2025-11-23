const HUE_MIREK_MIN = 153
const HUE_MIREK_MAX = 500

function turnHueLightOnOff(light, on) {
	if (on === undefined || on) {
		openHueCliCommand(["set", "light", light.id, "--on"])
	} else {
		openHueCliCommand(["set", "light", light.id, "--off"])
	}
}

function setHueLightBrightness(light, brightness) {
	openHueCliCommand(["set", "light", light.id, "--brightness", brightness])
}

function turnHueRoomOnOff(room, on) {
	if (on === undefined || on) {
		openHueCliCommand(["set", "room", room.id, "--on"])
	} else {
		openHueCliCommand(["set", "room", room.id, "--off"])
	}
}

function setHueRoomBrightness(room, brightness) {
	openHueCliCommand(["set", "room", room.id, "--brightness", brightness])
}

function setHueRoomColorTemp(room, mirek) {
	openHueCliCommand(["set", "room", room.id, "--temperature", mirek])
}

function enableHueScene(scene) {
	openHueCliCommand(["set", "scene", scene.id])
}

function openHueCliCommand(args) {
	Quickshell.execDetached([getOpenHueCli(pluginData), ...args])
}

function getOpenHueCli() {
	// TODO read setting for openhue-cli path
	// globalPluginData
	if (globalPluginData !== undefined && globalPluginData['openhue-cli:path'] !== undefined) {
		return globalPluginData['openhue-cli:path'];
	} else {
		return "openhue-cli";
	}
}

function getHueRoomIcon(hueName) {
	const mapping = {
		"living_room" : "chair",
	}

	if (hueName in mapping) {
		return mapping[hueName];
	} else {
		return "chair"; // TODO change placeholder to something more sensible
	}
}

function getHueLightIcon(hueName) {
	// TODO
	return "lightbulb_2";
}

function processOpenHueCliJson(jsonData) {
	var parsedOutput = JSON.parse(jsonData);

	if (parsedOutput.constructor !== [].constructor) {
		// check if array. openhue-cli will not return an array if there is a single room
		parsedOutput = [parsedOutput]
	}

	var allRooms = [];

	for (var i = 0; i < parsedOutput.length; i++) {
		const roomJson = parsedOutput[i];
		const roomArchetype = roomJson["HueData"]["metadata"]["archetype"]
		
		const groupedLightData = roomJson["GroupedLight"]["HueData"]

		const roomObject = {
			name: roomJson["Name"],
			id: roomJson["Id"],
			iconName: getHueRoomIcon(roomArchetype),
			on: groupedLightData["on"]["on"],
			brightness: groupedLightData["dimming"]["brightness"],
			turnOnOff(on) {
				turnHueRoomOnOff(this, on);
			},
			setBrightness(brightness) {
				setHueRoomBrightness(this, brightness);
			},
			setColorTemperature(ratio) {
				const mirek = (HUE_MIREK_MAX - HUE_MIREK_MIN) * ratio + HUE_MIREK_MIN
				setHueRoomColorTemp(this, Math.round(mirek))
			},

			lights: parseHueLights(roomJson),
			scenes: parseHueScenes(roomJson)
		}

		allRooms.push(roomObject);
	}


	return allRooms;
}

function parseHueLights(roomJson) {
	const devices = roomJson['Devices'];

	var allLights = [];

	for (var i = 0; i < devices.length; i++){
		const lightJson = devices[i];

		if (!('Light' in lightJson) || lightJson['Light'] === null) {
			// not a light
			continue
		}
		const lightObject = {
			name: lightJson["Light"]["Name"],
			id: lightJson["Light"]["Id"],
			iconName: getHueLightIcon(lightJson["Light"]["HueData"]["metadata"]["archetype"]),
			brightness: lightJson["Light"]["HueData"]["dimming"]["brightness"],
			on: lightJson["Light"]["HueData"]["on"]["on"],
			turnOnOff(onOff) {
				turnHueLightOnOff(this, onOff);
			},
			setBrightness(value) {
				setHueLightBrightness(this, value);
			}
		}

		allLights.push(lightObject);
	}

	return allLights;
}

function parseHueScenes(roomJson) {
	const scenesJson = roomJson["Scenes"];

	if (scenesJson === null) {
		return [];
	}

	var allScenes = [];

	for (var i = 0; i < scenesJson.length; i++) {
		const sceneJson = scenesJson[i];

		const sceneObject = {
			name: sceneJson["Name"],
			id: sceneJson["Id"],
			enable() {
				enableHueScene(this);
			}
		};

		allScenes.push(sceneObject);
	}

	allScenes.sort((a,b) => {
		if (a.name > b.name) {
			return 1;
		} else if (a.name < b.name) {
			return -1;
		}
	});

	return allScenes;
}

var globalPluginData

function getHueData(pluginData, completionHandler) {
	globalPluginData = pluginData; // TODO this is a little hacky?

	Proc.runCommand(
            "HueLights.Hue.fetchData",
            [getOpenHueCli(pluginData), "get", "rooms", "-j"],
            (stdout, exitCode) => {
                if (exitCode === 0) {
					const rooms = processOpenHueCliJson(stdout);
					completionHandler(rooms);
                } else {
                    console.error("Hue fetch command failed with exit code:", exitCode);
                }
            },
            100
        )
}

