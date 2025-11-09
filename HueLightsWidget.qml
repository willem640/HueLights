import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins
import "Hue.js" as Hue

// TODO: 
//x refactor hue functions,
//x change rooms to array, also in hue
//x add settings,
//x room slider,
//- add enable/disable services to getdata
//x color temp,
//x save opened/closed state
// actual hue integration,
// icons
//x make rooms PluginGlobalVar
// per-room open tab tracking?
// buggy behavior of list view when closing the lights tab when it is out of view
// add screenshots to readme
// optional scene/color temp view?
// remove empty rooms?
// Fix crash on empty room
// Color picker for RGB lights
// Timer for data refresh
// room brightness is not saved until refresh
// sort scenes

PluginComponent {
    id: root

	PluginGlobalVar {
		id: globalRooms
		varName: "rooms"
		defaultValue: []
	}

	property var currentlyOpenDropdown 

    function updateRoomsData() {
		var services = {
			"openhue-cli:enable": Hue.getHueData
		}

        var updateFunctions = [];

		for (var serviceSettingName in services) {
			if (pluginData[serviceSettingName] === true) {
				updateFunctions.push(services[serviceSettingName])
			}
		}

		var allUpdatedRooms = [];

        for (var i = 0; i < updateFunctions.length; i++) {
			var updatedRooms = updateFunctions[i](pluginData, (updatedRooms) => {
				for (var updatedIdx = 0; updatedIdx < updatedRooms.length; updatedIdx++) {
					var foundRoomInOldList = false;
					for (var oldRoomIdx = 0; oldRoomIdx < globalRooms.value.length; oldRoomIdx++) {
						if (globalRooms.value[oldRoomIdx].id == updatedRooms[updatedIdx].id) {
							globalRooms.value[oldRoomIdx] = updatedRooms[updatedIdx];
							foundRoomInOldList = true;
							break;
						}
					}
					if (!foundRoomInOldList) {
						globalRooms.value.push(updatedRooms[updatedIdx]);
					}
				}
	
				// TODO is a data race possible with multiple sources?
				// force an update
				globalRooms.set([...globalRooms.value]);
			}
		);
        }

        //globalRooms.set(allUpdatedRooms);
    }

    horizontalBarPill: Component {
        DankIcon {
            name: "lightbulb_2"
            size: Theme.iconSize - 6
        }
    }

    verticalBarPill: Component {
        DankIcon {
            name: "lightbulb_2"
            size: Theme.iconSize - 6
        }
    }

    popoutContent: Component {
        PopoutComponent {
            id: popout

            Component.onCompleted: () => updateRoomsData();

            headerText: "Hue lights"

            showCloseButton: true

            Column {
                id: popoutContentColumn
                width: parent.width
                spacing: Theme.spacingM
                DankListView {
                    id: roomsListView
                    width: parent.width
                    height: 400
					spacing: Theme.spacingL
					clip: true
                    model: globalRooms.value.map(thisRoom => {
                        return {
                            room: thisRoom
                        };
                    })
					delegate: RoomView {
						width: popoutContentColumn.width
						required property int index
						roomIndex: index
					}
                }
            }
        }
    }

    property int lightSliderHeight: 60

    component RoomView: Column {
		id: roomView
        required property int roomIndex
		required property var room
        width: parent.width
        spacing: Theme.spacingS

		LightSliderWithSwitch {
			lightOrRoom: roomView.room
			roomIndex: roomView.roomIndex
			isRoom: true
			labelFontSize: Theme.fontSizeLarge
		}

        LightsView {
            room: roomView.room
            roomIndex: roomView.roomIndex
        }

        SceneView {
			room: roomView.room
		}

		RoomColorTemperatureView {
			room: roomView.room
		}
    }

    component OpenableDropdown: Item {
        id: openableDropdown
        property int closedHeight: 0
        property bool isOpened: true
        clip: true

        // https://stackoverflow.com/questions/12333112/qml-animations-visible-property-changes
        states: [
            State {
                when: openableDropdown.isOpened
                name: "Open"
                PropertyChanges {
                    openableDropdown {
                        height: openableDropdown.childrenRect.height
                    }
                }
            },
            State {
                when: !openableDropdown.isOpened
                name: "Closed"
                PropertyChanges {
                    openableDropdown {
                        height: openableDropdown.closedHeight
                    }
                }
            }
        ]

        transitions: [
            Transition {
                from: "Open"
                to: "Closed"

                NumberAnimation {
                    target: openableDropdown
                    property: "height"
                    duration: 200
                    easing.type: Easing.InQuad
                }
            },
            Transition {
                from: "Closed"
                to: "Open"
                NumberAnimation {
                    target: openableDropdown
                    property: "height"
                    duration: 200
                    easing.type: Easing.OutQuad
                }
            }
        ]
    }

    component DropDownHeader: Item {
        id: dropDownHeader
        required property string iconName
        required property string text
        signal clicked(var mouseEvent)

        RowLayout {
            id: dropDownHeaderRowLayout
            spacing: Theme.spacingM
            width: parent.width
            DankIcon {
                id: dropDownIcon
                Layout.fillWidth: true
                Layout.horizontalStretchFactor: 1
                Layout.leftMargin: Theme.spacingS
                name: dropDownHeader.iconName
                size: Theme.iconSize
            }
            StyledText {
                Layout.fillWidth: true
                Layout.horizontalStretchFactor: 8
                verticalAlignment: Text.AlignVCenter
                text: dropDownHeader.text
                font.pixelSize: Theme.fontSizeLarge
                color: Theme.surfaceText
            }
        }
        MouseArea {
            id: dropDownHeaderMouseArea
            anchors.fill: dropDownHeader
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: event => dropDownHeader.clicked(event)
        }
    }

    component LightsView: StyledRect {
        id: lightsViewRect
        required property var room
        required property int roomIndex

        width: parent.width
        height: childrenRect.height
        color: Theme.surfaceContainerHigh

        OpenableDropdown {
            id: lightsViewOpenableDropdown
            width: parent.width
            height: childrenRect.height
            closedHeight: lightsViewHeader.height + Theme.spacingL
			isOpened: root.currentlyOpenDropdown == room.id + "-lightsViewOpenableDropdown"
			// Need to do string comparison because objects are regenerated every time the popout is opened
            ColumnLayout {
                id: lightsViewColumnLayout
                width: parent.width
                DropDownHeader {
                    id: lightsViewHeader
                    iconName: room.iconName
                    text: room.name + " lights"
					onClicked: {
						if (lightsViewOpenableDropdown.isOpened) {
							root.currentlyOpenDropdown = undefined
						} else {
							root.currentlyOpenDropdown = room.id + "-lightsViewOpenableDropdown"
						}
					}
                    Layout.fillWidth: true
                    Layout.topMargin: Theme.spacingS
                    Layout.bottomMargin: Theme.spacingS
                    Layout.preferredHeight: childrenRect.height
                }

                ColumnLayout {
                    id: lightsListColumnLayout
                    Layout.bottomMargin: Theme.spacingS
                    Repeater {
                        model: room.lights !== undefined ? room.lights.map(light => {
                            return {
                                lightOrRoom: light
                            };
                        }) : []
                        delegate: LightSliderWithSwitch {
                            required property int index
                            roomIndex: lightsViewRect.roomIndex
                            lightIndex: index
                            color: Theme.surfaceContainerHighest
                            Layout.leftMargin: Theme.spacingS
                            Layout.rightMargin: Theme.spacingS
                            Layout.fillWidth: true
                        }
                    }
                }
            }
        }
    }

    component SceneView: StyledRect {
        id: sceneViewRect
        required property var room

        width: parent.width
        height: childrenRect.height
        color: Theme.surfaceContainerHigh

        OpenableDropdown {
            id: sceneViewOpenableDropdown
            width: parent.width
            height: childrenRect.height
            closedHeight: sceneViewHeader.height + Theme.spacingL
			isOpened: root.currentlyOpenDropdown == room.id + "-sceneViewOpenableDropdown"
            ColumnLayout {
                id: sceneViewColumnLayout
                width: parent.width
                DropDownHeader {
                    id: sceneViewHeader
                    iconName: "scene"
                    text: room.name + " scenes"
					onClicked: {
						if (sceneViewOpenableDropdown.isOpened) {
							root.currentlyOpenDropdown = undefined
						} else {
							root.currentlyOpenDropdown = room.id + "-sceneViewOpenableDropdown"
						}
					}
                    Layout.fillWidth: true
                    Layout.topMargin: Theme.spacingS
                    Layout.bottomMargin: Theme.spacingS
                    Layout.preferredHeight: childrenRect.height
                }

                ColumnLayout {
                    id: sceneListColumnLayout
                    Layout.bottomMargin: Theme.spacingS
                    Repeater {
                        model: room.scenes.map(scene => {
                            return {
                                scene: scene
                            };
                        })
                        delegate: SceneViewSingle {
                            Layout.leftMargin: Theme.spacingS
                            Layout.rightMargin: Theme.spacingS
                            Layout.fillWidth: true
                        }
                    }
                }
            }
        }
    }

    component SceneViewSingle: StyledRect {
        id: sceneRect
        required property var scene
        width: parent.width
        height: 40
        color: sceneArea.containsMouse ? Theme.surfaceContainerHighest : "transparent"
        radius: Theme.cornerRadius

        StyledText {
            anchors.fill: parent
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            text: scene.name
            font.pixelSize: Theme.fontSizeMedium
            color: Theme.surfaceText
        }

        MouseArea {
            id: sceneArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
			onClicked: {
				scene.enable() 
			}
        }
    }

    component LightSliderWithSwitch: StyledRect {
		id: lightSliderWithSwitchRect
        required property var lightOrRoom
        property int roomIndex
        property int lightIndex
		property bool isRoom: false // only used when updating the global rooms variable, rest of the functionality is the same because room and light methods are the same

		property int labelFontSize: Theme.fontSizeMedium

        width: parent.width
        radius: Theme.cornerRadius
        color: Theme.surfaceContainerHigh
        height: lightSliderHeight

        RowLayout {
            spacing: Theme.spacingM
            anchors.fill: parent
            DankIcon {
                id: lightIcon
                Layout.fillWidth: true
                Layout.horizontalStretchFactor: 1
                Layout.leftMargin: 8
                name: lightOrRoom.iconName
                size: Theme.iconSize
            }
            ColumnLayout {
                Layout.fillWidth: true
                Layout.horizontalStretchFactor: 8
                StyledText {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.topMargin: Theme.spacingM 
                    verticalAlignment: Text.AlignVCenter
                    text: lightOrRoom.name
					font.pixelSize: lightSliderWithSwitchRect.labelFontSize
					color: Theme.surfaceText
                }
                DankSlider {
                    id: lightSlider
                    Layout.fillWidth: true
                    Layout.bottomMargin: Theme.spacingXS
                    Layout.fillHeight: true
                    minimum: 1
                    maximum: 100
                    value: lightOrRoom.brightness
                    wheelEnabled: false // doesn't work with onSliderDragFinished
                    onSliderDragFinished: finalValue => {
                        lightOrRoom.setBrightness(finalValue);
						if (roomIndex !== undefined && lightIndex !== undefined) {
                        	globalRooms.value[roomIndex].lights[lightIndex].brightness = finalValue;
						} else if (roomIndex !== undefined && isRoom) {
							globalRooms.value[roomIndex].brightness = finalValue
						}
                    }
                }
            }
            Item {
                Layout.fillWidth: true
                Layout.minimumWidth: lightToggle.width
                Layout.horizontalStretchFactor: 1
                Layout.rightMargin: 5

                DankToggle {
                    id: lightToggle
                    anchors.centerIn: parent
                    //width: parent.width * 0.3
                    checked: lightOrRoom.on
                    onToggleCompleted: state => {
                        lightOrRoom.turnOnOff(state);
						if (roomIndex !== undefined && lightIndex !== undefined) {
							globalRooms.value[roomIndex].lights[lightIndex].on = state;
						} else if (roomIndex !== undefined && isRoom) {
							globalRooms.value[roomIndex].on = state
						}
                    }
                }
            }
        }
    }


	component RoomColorTemperatureView: StyledRect {
        id: roomColorTemperatureViewRect
        required property var room

        width: parent.width
        height: childrenRect.height
        color: Theme.surfaceContainerHigh

        OpenableDropdown {
            id: roomColorTemperatureViewOpenableDropdown
            width: parent.width
            height: childrenRect.height
            closedHeight: roomColorTemperatureViewHeader.height + Theme.spacingL
			isOpened: root.currentlyOpenDropdown == room.id + "-roomColorTemperatureViewOpenableDropdown"
            ColumnLayout {
                id: roomColorTemperatureViewColumnLayout
                width: parent.width
                DropDownHeader {
                    id: roomColorTemperatureViewHeader
                    iconName: "thermometer"
                    text: room.name + " color temperature"
					onClicked: {
						if (roomColorTemperatureViewOpenableDropdown.isOpened) {
							root.currentlyOpenDropdown = undefined
						} else {
							root.currentlyOpenDropdown = room.id + "-roomColorTemperatureViewOpenableDropdown"
						}
					}
                    Layout.fillWidth: true
                    Layout.topMargin: Theme.spacingS
					Layout.bottomMargin: Theme.spacingS
                    Layout.preferredHeight: childrenRect.height
                }


				Item {
					// surround in Item so MouseArea does not get rounded corners
					id: colorTempItem
					Layout.fillWidth: true
					Layout.leftMargin: Theme.spacingL
					Layout.rightMargin: Theme.spacingL
					Layout.bottomMargin: Theme.spacingL
					Layout.preferredHeight: 2 * Theme.cornerRadius

					StyledRect {
						id: colorTempGradient
						anchors.fill: parent
					
						gradient: Gradient {
								orientation: Gradient.Horizontal
								GradientStop { position: 0.0; color: "#FF890E" }
								GradientStop { position: 1.0; color: "#FFFFFB"}
						}
						
					
					}
					MouseArea {
						anchors.fill: parent
						hoverEnabled: true
						cursorShape: Qt.PointingHandCursor
						onClicked: event => {
							const percent = event.x / this.width
							const graceArea = 0.05
							var percentAdjusted = percent / (1 - 2 * graceArea) - graceArea
							// consider first and last 5% to mean minimum and maximum temerature, otherwise setting the lowest value is difficult
							if (percentAdjusted < 0) {
								percentAdjusted = 0
							} else if (percentAdjusted > 1) {
								percentAdjusted = 1
							}
							room.setColorTemperature(1 - percentAdjusted)
						}
					}
				}


            }
        }
    }

    popoutWidth: 400
}
