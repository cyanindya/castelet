# Castelet Visual Novel Framework

## What is Castelet?
**Castelet** is a visual novel framework built on Godot Engine. The aim of this project is to facilitate visual novel-like story presentation by using dedicated script files. The scripting language of Castelet is deliberately designed to be similar with existing script-based visual novel development kits such as Ren'Py and Naninovel, thus helping to focus on developing the narrative content.

This project is a personal hobby project and thus will be updated on irregular basis, and as such, this is still *heavily* in progress. If you wish to use a more 'complete' framework, it is advised to check out other projects such as [Rakugo Dialogue System](https://github.com/rakugoteam/Rakugo-Dialogue-System) or [Dialogic](https://github.com/coppolaemilio/dialogic).

The development roadmap of this project can be viewed in this [public Trello board](https://trello.com/b/wMPIttki/castelet).

## Getting Started
Although this framework mostly uses its own scripting language for mapping out the story content, It is **heavily recommended** to learn the basics of Godot Engine and GDScript first to understand how the framework works. Understanding how Godot Engine works will also help if you wish to customize this framework.

The SampleProjects folder contains example of this framework's usage. Run this project to see how they are in action.

In general, there are several things you need to prepare to create a basic visual novel scene using Castelet:
- a .tsc *(**t**heater **sc**ript)* file containing the scene to be displayed
- various assets such as background images, character sprites, and audio files
- .tres resource files derived from `PropResource` class, which define "props" of the story. See the documentation of `PropResource` for details.
- (Optional) A .tres file containing definitions of the audio files, derived from `AudioListResource`.

Once you have all of them prepared, create a new `TheaterNode` instance, and assign the associated .tsc script file to `script_file` property.

## Customizing Castelet
Perhaps, it may be desirable for you to use some of existing nodes or resources available already in your project -- for example, you may want to use your own audio manager instead of the built-in one provided by this framework. In some cases, you may want to modify internal workings of Castelet to better suit your game. In that case, you may need to modify the following `.gd` and/or `.tscn` files:
- `ScriptParser` is the file responsible for reading the `.tsc` script and convert it into syntax trees to be read by Castelet.
- `TheaterNode` is where the resulting syntax trees are processed to display or hide various components of your scenes, which are delegated to `StageNode` or `GUINode`.
- `StageNode` is where all of your visual assets (backgrounds, characters, event illustrations) are displayed.
- `GUINode` is the file responsible for displaying the dialogue from your script and control various GUI elements related to Castelet, such as dialogue history (backlog) window or quick-menu buttons.

Do note that as more features are added, these components will be reworked later.

## Documentation
(in progress)

## Contact and Support
If you found issues or suggestions, feel free to open up an issue in the Issues tab. Do note that the development is mainly conducted based on the published development roadmap above -- and as such, certain non-critical requests may have to wait.
