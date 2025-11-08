## A plugin to control Hue Lights in DankMaterialShell
Inspired by [the Gnome smart home plugin](https://github.com/vchlum/smart-home)
I am still testing some parts of it, but I'm planning to release it to the DMS plugin registry soon. 

Currently, only Hue lights are supported through [openhue-cli](https://github.com/openhue/openhue-cli). To use the plugin, first install `openhue-cli` and set it up to connect to your bridge:
```sh
$ openhue-cli setup
```
When setup is finished, the plugin should detect and be able to control your rooms and lights.

## Integrating other lights
It should be relatively easy to integrate other services. See [CONTRIBUTING.md](CONTRIBUTING.md) for more information.

## License
This project is available under the GPLv3 (see [LICENSE](LICENSE)).
