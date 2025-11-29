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

const HUE_ICON_NAMES_MAPPING = {
    "unknown_archetype": "lightbulb_2",
    "classic_bulb": "lightbulb_2",
    "sultan_bulb": "lightbulb_2",
    "flood_bulb": "lightbulb_2",
    "spot_bulb": "lightbulb_2",
    "candle_bulb": "lightbulb_2",
    "luster_bulb": "lightbulb_2",
    "pendant_round": "light",
    "pendant_long": "fluorescent",
    "ceiling_round": "light",
    "ceiling_square": "fluorescent",
    "floor_shade": "floor_lamp",
    "floor_lantern": "floor_lamp",
    "table_shade": "table_lamp",
    "recessed_ceiling": "detector_alarm",
//    "recessed_floor": "",
    "single_spot": "nest_cam_wall_mount",
    "double_spot": "nest_cam_wall_mount",
    "table_wash": "table_lamp",
    "wall_lantern": "wall_lamp",
    "wall_shade": "wall_lamp",
//    "flexible_lamp": "lightbulb_2",
    "ground_spot": "nest_cam_wired_stand",
    "wall_spot": "nest_cam_iq_outdoor",
    "plug": "power",
    "hue_go": "nest_cam_wired_stand",
//    "hue_lightstrip": "",
    "hue_iris": "nest_cam_wired_stand",
    "hue_bloom": "nest_cam_wired_stand",
    "bollard": "battery_5_bar",
//    "wall_washer": "",
    "hue_play": "sliders",
    "vintage_bulb": "lightbulb_2",
    "vintage_candle_bulb": "lightbulb_2",
    "ellipse_bulb": "lightbulb_2",
    "triangle_bulb": "lightbulb_2",
    "small_globe_bulb": "lightbulb_2",
    "large_globe_bulb": "lightbulb_2",
    "edison_bulb": "lightbulb_2",
    "christmas_tree": "park",
//    "string_light": "",
    "hue_centris": "nest_cam_wall_mount",
//    "hue_lightstrip_tv": "",
//    "hue_lightstrip_pc": "",
//    "hue_tube": "",
//    "hue_signe": "",
    "pendant_spot": "nest_cam_iq_outdoor",
    "ceiling_horizontal": "detector_alarm",
    "ceiling_tube": "detector_alarm",
//    "up_and_down": "lightbulb_2",
//    "up_and_down_up": "lightbulb_2",
//    "up_and_down_down": "lightbulb_2",
    "hue_floodlight_camera": "nest_cam_floodlight",

    "living_room": "chair",
    "kitchen": "kitchen",
    "dining": "dine_lamp",
    "bedroom": "bed",
    "kids_bedroom": "single_bed",
    "bathroom": "bathroom",
    "nursery": "crib",
    "recreation": "padel",
    "office": "business_center",
    "gym": "exercise",
    "hallway": "hallway",
    "toilet": "wc",
    "front_door": "door_front",
    "garage": "garage_home",
    "terrace": "chair_umbrella",
    "garden": "local_florist",
    "driveway": "car_repair",
    "carport": "laptop_car",
    "home": "home",
    "downstairs": "home",
    "upstairs": "home",
    "top_floor": "home",
    "attic": "home",
    "guest_room": "hotel",
    "staircase": "stairs",
    "lounge": "weekend",
    "man_cave": "sports_esports",
    "computer": "computer",
    "studio": "brush",
    "music": "headphones",
    "tv": "tv_gen",
    "reading": "book_ribbon",
    "closet": "dresser",
    "storage": "box",
    "laundry_room": "local_laundry_service",
    "balcony": "balcony",
    "porch": "tatami_seat",
    "barbecue": "outdoor_grill",
    "pool": "pool",
    "other": "door_open"
}

function getHueRoomIcon(hueName) {
	if (hueName in HUE_ICON_NAMES_MAPPING) {
		return HUE_ICON_NAMES_MAPPING[hueName];
	} else {
		return "door_open"; 
	}
}

function getHueLightIcon(hueName) {
	if (hueName in HUE_ICON_NAMES_MAPPING) {
		return HUE_ICON_NAMES_MAPPING[hueName];
	} else {
		return "lightbulb_2";
	}
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

