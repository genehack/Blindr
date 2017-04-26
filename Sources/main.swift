import Foundation
import SwiftCLI

// [wg] Using the [] and [:] notation for arrays and dictionaries greatly reduces
// the clutter caused by <Array<Dictionary... so I'm going to do that throughout
//
// Although I could also use a typealias to reduce clutter even more
//typealias SceneFormat = [String: Any]

// [wg] A small wrapper of scene data, just the decodedValue and id, but you could
// add the name for completeness, or if you're going to use it elsewhere
//
// By adding a wrapper and using a failable initializer I can throw away the majority
// of the levels of indentation in later methods.
struct Scene {
    let decodedValue: String
    let id: String

    // [wg] I noticed in the original code you only process the data if you've got
    // a scene with a decoded_value and an id. If you don't then you throw the scene
    // away.
    //
    // This failable initializer will do the same thing, only creating the
    // Scene if those two things exist in the dictionary returned in the json
    // If they don't then a Scene won't be created and you can ignore/filter them out
    // using flatMap later on in getScenesList()
    init?(dict: [String: Any]) {
        guard
            let id = dict["id"] as? Int,
            let name = dict["name"] as? String,
            let data = Data(base64Encoded: name),
            let decodedValue = String(data: data, encoding: .utf8)
        else {
            return nil
        }

        self.decodedValue = decodedValue
        self.id = String(id)
    }
}

class RunSceneCommand: Command {
    let name = "run_scene"
    let shortDescription = "Activate a scene by name"
    let sceneName = Parameter()

    func execute() throws {
        Hub().run(scene: sceneName.value)
    }
}

class ScenesCommand: Command {
    let name = "scenes"
    let shortDescription = "Get a list of defined scenes from the hub"

    func execute() throws {
        let scenes = Hub().scenesByName

        if scenes.isEmpty {
            print("Could not detect any scenes")
        }
        else {
            print("SCENES")
            print("------")
            listOfScenes.forEach {
                print($0)
            }
        }
    }
}

CLI.setup(name: "Blindr")
CLI.register(command: RunSceneCommand())
CLI.register(command: ScenesCommand())
_ = CLI.go()
