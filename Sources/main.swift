import Foundation
import Just
import SwiftCLI

extension String {
    func matchingStrings(regex: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: regex, options: NSRegularExpression.Options.caseInsensitive) else { return [] }
        let nsString = self as NSString
        let matches  = regex.matches(in: self, options: [], range: NSMakeRange(0, nsString.length))
        var results  = [String]()
        for ranges in matches {
            for rangeIdx in 1 ..< ranges.numberOfRanges {
                results.append(nsString.substring(with: ranges.rangeAt(rangeIdx)))
            }
        }
        return results
    }
}

func runShellProcess (cmd: String, arguments: [String]) -> String? {
    let pipe = Pipe()
    let task = Process()

    task.launchPath     = cmd
    task.arguments      = arguments
    task.standardOutput = pipe

    task.launch()

    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    if let output = String(data: data, encoding: .utf8) {
        return output
    }
    else {
        fatalError("Couldn't run '\(cmd)'")
    }
}

// [wg] Nothing interently wrong with the getHupIp method, but "one cool trick" (tm) is you can do
//
//  private extension String {
//      static let hupIP = "192.168.1.122"
//  }
//
// and then
//  let res = Just.get("http://" + .hupIP + "/" + frag)
//
// I use it a lot, it's a nice way to keep hard coded strings and magic numbers away from the code

func getHubIp () -> String {
    if let smbInfo = runShellProcess(cmd: "/usr/bin/smbutil", arguments: ["lookup", "PDBU-Hub3.0"]) {
        if let hubIp = smbInfo.matchingStrings(regex: "from ([\\d\\.]+)").first {
            return hubIp
        }
    }

    fatalError("Couldn't fetch hub IP address - is the hub okay? ")
}

func sendGetReq (_ frag: String) -> HTTPResult {
    // [wg] Not a Swift comment, but a general iOS/Foundation one, but it's probably best to
    // work directly with URL types rather than strings.
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

// [wg] No longer returning an optional, now it's just an array of Scene values.
// Instead of being optional, now it can just be an empty array. This helps to
// get rid of one of the levels of indentation in later methods
func getScenesList () -> [Scene] {
    let res  = sendGetReq("api/scenes")
    let json = res.json as? [String: AnyObject]

    guard let sceneData = json?["sceneData"] as? [[String: Any]] else { // [wg] probably would look better as [SceneFormat]
        // [wg] Invalid JSON, so returning empty
        return []
    }

    // [wg] Using flatMap will create an array of Scenes, while filtering out all nils
    return sceneData.flatMap {
        Scene(dict: $0)
    }
}

class RunSceneCommand: Command {
    let name = "run_scene"
    let shortDescription = "Activate a scene by name"
    let sceneName = Parameter()

    // [wg] The goal here is to reduce the number of indents, and because getScenesList() is doing all
    // of the hard work we're now left with a method that just returns us exactly what we need.
    func execute() throws {
        // [wg] Now that getScenesList() returns an array we can just loop on it, using forEach
        // If the array is empty, this will do nothing
        getScenesList().forEach {
            if $0.decodedValue == sceneName.value {
                _ = sendGetReq("api/scenes?sceneid=" + $0.id)
            }
        }

        // [wg] Overkill-y Swift-y alternative, filter out scenes not matching
        // sceneName.value and then call sendGetReq
        //    getScenesList().filter { scene in
        //        scene.decodedValue == sceneName.value
        //    }
        //    .forEach {
        //        _ = sendGetReq("api/scenes?sceneid=" + $0.id)
        //    }

    }
}

class ScenesCommand: Command {
    let name = "scenes"
    let shortDescription = "Get a list of defined scenes from the hub"

    // [wg] Same approach as above, except we're creating the listOfScenes array, so instead
    // of using forEach, we use map to create elements of an array containing the data we want.
    // This also means we can make listOfScenes immutable
    func execute() throws {
        let listOfScenes = getScenesList().map {
            $0.decodedValue
        }

        // [wg] Inverted the if-statement to take advantage of the array's isEmpty property, which is
        // quicker than comparing count values
        if listOfScenes.isEmpty {
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
