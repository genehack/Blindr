import Foundation
import SwiftCLI

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
