import Foundation

typealias SceneData = [String:Any]

struct Scene {
    let id: String
    let name: String

    init? (dict: SceneData) {
        guard
          let id        = dict["id"] as? Int,

          let codedName = dict["name"] as? String,
          let data      = Data(base64Encoded: codedName),
          let name      = String(data: data, encoding: .utf8)

        else { return nil }

        self.id = String(id)
        self.name = name
    }
}

