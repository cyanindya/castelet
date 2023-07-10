# Castelet Visual Novel Framework

## What is Castelet?
**Castelet** is a visual novel framework built on Godot Engine. The aim of this project is to facilitate Godot Engine users to easily integrate visual novel-like story presentation into their projects by using dedicated script files. The scripting language of Castelet is deliberately designed to be similar with existing script-based visual novel development kits such as Ren'Py and Naninovel, thus helping users to focus on developing the narrative content.

This project is a personal hobby project and thus will be updated on irregular basis, and as such, this is still *heavily* in progress. If you wish to use a more 'complete' framework, it is advised to check out other projects such as [Rakugo Dialogue System](https://github.com/rakugoteam/Rakugo-Dialogue-System) by Team Rakugo.

The development roadmap of this project can be viewed in this [public Trello board](https://trello.com/b/wMPIttki/castelet).

## Getting Started
Although this framework mostly uses its own scripting language for mapping out the story content, It is **heavily recommended** to learn the basics of Godot Engine and GDScript first to understand how the framework works.

The SampleProjects folder contains example of this framework's usage. Run this project to see how they are in action.

In general, there are several things you need to prepare to create a basic visual novel scene using Castelet:
- a .tsc *(**t**heater **sc**ript)* file containing the scene to be displayed
- various assets such as background images, character sprites, and audio files
- .tres resource files derived from `PropResource` class. These files contain definitions and groupings related to the visual assets (dubbed as **props** onwards). A `PropResource` resource file contains the following information:
  - `prop_id` : The unique identifier associated with the prop. For example, you can use `bg` as identifier for background images and `adrias` for sprites of a character named "Adrias". This ID can also be used to define a speaking character in the script.
  - `prop_name`: The name associated with the prop, this is mainly used for dialogue purposes. An example of this would be a character's name.
  - `variants`: Contains all visual assets related to the prop and their unique identifiers, stored as dictionary of key-value pairs. Example:
    ```
    variants = {
        "default" : "res://assets/images/sprites/adrias/base.png"
        "happy" : "res://assets/images/sprites/adrias/happy.png"
        "angry" : "res://assets/images/sprites/adrias/angry.png"
        ...
        etc.
    }
    ```
  - `x_anchor` : Defines horizontal pivot point of the visual assets, ranging from 0.0 (left) to 1.0 (right). This is set to 0.5 (center) by default.
  - `y_anchor` : Defines vertical pivot point of the visual assets, ranging from 0.0 (top) to 1.0 (bottom). This is set to 0.5 (center) by default.
  - `centered` : Sets the pivot point of the visual assets to center by enabling the `centered` property from the `Sprite2D` class. This is disabled by default since it interferes with how `x_anchor` and `y_anchor` work -- if this is enabled, the previous two values will be ignored.
- (Optional) A .tres file containing definitions of the audio files, derived from `Audio`

Once you have all of them prepared, create a new `TheaterNode` instance, and assign the associated .tsc script file to `script_file` property.

## Documentation