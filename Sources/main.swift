import Foundation
import Just
import SwiftCLI

func getHubIp () -> String {
    // TODO FIXME make this use mDNS or something...
    return "192.168.1.122"
}

func sendGetReq (_ frag: String) -> HTTPResult {
    let res = Just.get("http://" + getHubIp() + "/" + frag)

    // FIXME this takes a long time to timeout. maybe see if you can reduce that value?
    if ( !res.ok ) {
        print("Whoops, an error occured!")
        print("Reason: " + res.reason)
        fatalError("DEAD")
    }
    else {
        return res
    }
}

func getScenesList () -> Array<Dictionary<String, Any>>? {
    let res  = sendGetReq("api/scenes")
    let json = res.json as? Dictionary<String,AnyObject>

    if let sceneData = json?["sceneData"] as? Array<Dictionary<String, Any>> {
        return sceneData
    }
    else {
        return nil
    }
}

class RunSceneCommand: Command {
    let name = "run_scene"
    let shortDescription = "Activate a scene by name"
    let sceneName = Parameter()
    func execute() throws {
        if let scenes = getScenesList() {
            for scene in scenes {
                if let name = scene["name"] as? String {
                    // FIXME you're doing this in two places, so it should be a function
                    let data = Data(base64Encoded: name)
                    // FIXME gotta be a better way to do this
                    if let decoded_value = String(data: data!, encoding: .utf8) {
                        if decoded_value == sceneName.value {
                            if let sceneId = scene["id"] as? Int {
                                _ = sendGetReq("api/scenes?sceneid=" + String(sceneId))
                            }
                        }
                    }
                }
            }
        }
    }
}

class ScenesCommand: Command {
    let name = "scenes"
    let shortDescription = "Get a list of defined scenes from the hub"
    func execute() throws {
        var listOfScenes = [String]()
        if let scenes = getScenesList() {
            for scene in scenes {
                if let name = scene["name"] as? String {
                    // FIXME you're doing this in two places, so it should be a function
                    let data = Data(base64Encoded: name)
                    // FIXME gotta be a better way to do this and maybe without the bang?
                    if let decoded_value = String(data: data!, encoding: .utf8) {
                        listOfScenes.append(decoded_value)
                    }
                }
            }
        }

        if listOfScenes.count > 0 {
            print("SCENES")
            print("------")
            for scene in listOfScenes {
                print(scene)
            }
        }
        else {
            print("Could not detect any scenes")
        }
    }
}

CLI.setup(name: "Blindr")
CLI.register(command: RunSceneCommand())
CLI.register(command: ScenesCommand())
_ = CLI.go()
