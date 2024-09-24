## PropResource
 A type of resource that contains definitions and groupings related to the visual assets (dubbed as **props** onwards). A `PropResource` resource file contains the following information:
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
  