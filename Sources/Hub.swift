import Foundation
import Just

class Hub {

    let ip: String

    // FIXME would i be better off with this as a `init?()` ?
    init () {
        guard
          // FIXME seems like i need a broadcast ping here to wake the fucking thing up...

          let smbInfo = runShellProcess(cmd: "/usr/bin/smbutil",
                                        arguments: ["lookup", "PDBU-Hub3.0"]),
          let hubIp = smbInfo.getCapturedStrings(regex: "from ([\\d\\.]+)").first
        else {
            // FIXME gotta be a better way of dealing with this - return a nil? throw an exception?
            fatalError("Couldn't fetch hub IP address - is the hub okay? ")
        }

        // FIXME what if hubIp is empty? (i.e., what if the regex matched nothing)
        self.ip = hubIp
    }

    var scenes: [Scene] {
        let res  = sendGetReq("api/scenes")

        guard
          let json      = res.json as? [String: AnyObject],
          let sceneData = json["sceneData"] as? [SceneData]

        else {
            return [] // Parsing failed, somehow, so returning empty
        }

        return sceneData.flatMap { Scene(dict: $0) }
    }

    var scenesByName: [String] {
        return self.scenes.map { $0.name }
    }

    func run (scene scenename: String) {
        // FIXME if we had a data structure that was <name:Scene> then
        // we wouldn't need to loop...
        self.scenes.forEach {
            if $0.name == scenename {
                // FIXME probably ought to do something with the
                // return value here, make sure it's not an error or
                // something...
                _ = self.sendGetReq("api/scenes?sceneid=" + $0.id)
                return // we're done, get out
            }
        }
    }

    private func sendGetReq (_ frag: String) -> HTTPResult {
        let url = "http://\(self.ip)/\(frag)"
        let res = Just.get(url, timeout: 0.5)

        if ( !res.ok ) {
            print("Whoops, an error occured!")
            print("Reason: " + res.reason)
            // FIXME throw a fucking exception or something, punk
            fatalError("DEAD")
        }
        else {
            // FIXME
            return res
        }
    }
}

extension String {
    func getCapturedStrings(regex: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: regex,
                                                   options: NSRegularExpression.Options.caseInsensitive)
        else { return [] }

        let nsString = self as NSString
        let matches  = regex.matches(in: self, options: [], range: NSMakeRange(0, nsString.length))

        var results  = [String]()
        for ranges in matches {
            // skip 0 because we don't want the whole match, just the captures
            for rangeIdx in 1 ..< ranges.numberOfRanges {
                results.append(nsString.substring(with: ranges.rangeAt(rangeIdx)))
            }
        }

        return results
    }
}

fileprivate func runShellProcess (cmd: String, arguments: [String]) -> String? {
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
        // FIXME this should throw an exception
        fatalError("Couldn't run '\(cmd)'")
    }
}
