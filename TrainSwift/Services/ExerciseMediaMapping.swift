//
//  ExerciseMediaMapping.swift
//  TrainSwift
//
//  Auto-generated mapping
//

// Auto-generated exercise media mapping
// Maps exercise IDs to Bunny.net video GUIDs or image URLs

import Foundation

enum MediaType {
    case video
    case image
}

struct ExerciseMedia {
    let guid: String?
    let imageFilename: String?
    let mediaType: MediaType

    init(videoGuid: String) {
        self.guid = videoGuid
        self.imageFilename = nil
        self.mediaType = .video
    }

    init(imageFilename: String) {
        self.guid = nil
        self.imageFilename = imageFilename
        self.mediaType = .image
    }
}

struct ExerciseMediaMapping {
    static let imageBaseURL = "https://train-strength.b-cdn.net"

    static let mapping: [String: ExerciseMedia] = [
        "EX004": ExerciseMedia(videoGuid: "cbd0a4ec-4b04-4697-ab65-b47de8c4b29b"),
        "EX005": ExerciseMedia(videoGuid: "8eacc0eb-0a4b-4c8f-87b4-05520ea0f12c"),
        "EX006": ExerciseMedia(videoGuid: "34d7ed3e-6652-4038-97f3-4627c0dfb776"),
        "EX012": ExerciseMedia(videoGuid: "adc5f995-c78b-4f27-83b0-3ba33b15c5a5"),
        "EX013": ExerciseMedia(videoGuid: "80744687-b957-444f-b758-b3e88cad5916"),
        "EX014": ExerciseMedia(videoGuid: "4b1f1e7a-2e46-4871-9786-1c5c816d3b16"),
        "EX015": ExerciseMedia(videoGuid: "4a7aeaac-28d9-488a-ae75-29ebfd44a64e"),
        "EX017": ExerciseMedia(videoGuid: "cd95ff49-3c92-4012-b09b-d49d283422c7"),
        "EX019": ExerciseMedia(videoGuid: "c687f686-31af-4f2c-a1e2-5ed3c3ff87f1"),
        "EX020": ExerciseMedia(videoGuid: "38c84625-3f03-4ffe-808a-0589e478b192"),
        "EX021": ExerciseMedia(videoGuid: "df855098-096b-4297-beb8-99fe07d72357"),
        "EX022": ExerciseMedia(videoGuid: "1b291e47-9c48-4a0f-b820-27d34a4a5b4b"),
        "EX023": ExerciseMedia(videoGuid: "f736be5b-5218-4e16-bad5-2d7071cdcf46"),
        "EX025": ExerciseMedia(videoGuid: "13be069d-995b-43ba-afd6-6a21c3b15a4e"),
        "EX026": ExerciseMedia(videoGuid: "e9d5e0de-4254-4a55-9264-44d87390b62a"),
        "EX027": ExerciseMedia(videoGuid: "7f53d51f-f1c3-43e0-99af-3e0bfc1ef1e7"),
        "EX028": ExerciseMedia(videoGuid: "d4bfe4f6-bf50-4e7a-a2cc-44a28c224b61"),
        "EX029": ExerciseMedia(videoGuid: "249f7db9-e731-4f4a-a224-d090fb5ae0f1"),
        "EX030": ExerciseMedia(videoGuid: "52ff110f-4dbe-4cff-83bf-68b89d7926d4"),
        "EX032": ExerciseMedia(imageFilename: "07151101-Side-Plank-(male)_Waist-FIX_max.png"),
        "EX033": ExerciseMedia(videoGuid: "f8be8487-5a9b-4d30-9f47-c28d63ab693d"),
        "EX034": ExerciseMedia(videoGuid: "5fbc336b-f985-4883-b099-cafe6fffe781"),
        "EX035": ExerciseMedia(videoGuid: "d12fe4aa-2954-4f97-a8ed-7b277b5cf484"),
        "EX036": ExerciseMedia(videoGuid: "14a8bf12-36da-4df4-847f-bffaa047480e"),
        "EX037": ExerciseMedia(videoGuid: "3c3b0979-e5d7-4d47-8c09-d304851b17cc"),
        "EX038": ExerciseMedia(videoGuid: "6b976b47-affb-473b-91ba-0b92f603a015"),
        "EX040": ExerciseMedia(videoGuid: "4eaf1007-6b4c-4acd-ba1f-2c7204d4169c"),
        "EX042": ExerciseMedia(videoGuid: "8eb200b4-4673-4edc-82f3-9bab875d2064"),
        "EX043": ExerciseMedia(videoGuid: "39b349e5-d472-4077-b526-c42559695b7c"),
        "EX044": ExerciseMedia(videoGuid: "c5de388c-2c04-45e5-aa96-5f82439c2bda"),
        "EX045": ExerciseMedia(videoGuid: "8c2c0ba2-0f7d-420e-98fb-79f1d878a962"),
        "EX046": ExerciseMedia(videoGuid: "1c371ac2-aa20-47a4-93ab-3bbc7c789568"),
        "EX047": ExerciseMedia(videoGuid: "1234dabd-956b-45c2-8256-d777e730070f"),
        "EX048": ExerciseMedia(videoGuid: "b1ef1651-b4bb-4040-99a6-8e47c613af22"),
        "EX049": ExerciseMedia(videoGuid: "dc23cf29-ae05-4205-a2dc-c82823254d5b"),
        "EX050": ExerciseMedia(videoGuid: "805a8936-87a8-432a-99f0-9181e2ac08ac"),
        "EX051": ExerciseMedia(videoGuid: "a116e629-657a-434f-bbe1-e1e37bfc15a4"),
        "EX052": ExerciseMedia(videoGuid: "bddcf934-9fd7-40b9-ab61-9fff12baf8d6"),
        "EX053": ExerciseMedia(videoGuid: "465c69af-ba8c-4f88-8c9d-e2dcec3ea3ad"),
        "EX054": ExerciseMedia(videoGuid: "25fdd19d-e56c-41ed-9820-d8fa15908c34"),
        "EX055": ExerciseMedia(videoGuid: "0377a64a-ec30-46d4-bab9-8864c41eeace"),
        "EX056": ExerciseMedia(videoGuid: "aba6d56e-3f0e-4024-84a6-0814072a6b2b"),
        "EX057": ExerciseMedia(videoGuid: "25f3a5cc-db9d-47e2-8892-8ffec2d35408"),
        "EX058": ExerciseMedia(videoGuid: "111490ef-5549-4f98-b6cd-c4bdd6e3939e"),
        "EX060": ExerciseMedia(videoGuid: "6fbefd4c-ad4a-440d-a190-b9e17889950d"),
        "EX065": ExerciseMedia(videoGuid: "af243431-f6ed-4d70-bb8f-742e6d68d875"),
        "EX067": ExerciseMedia(videoGuid: "b86d513e-26f5-4d52-954e-c1735e17b49e"),
        "EX068": ExerciseMedia(videoGuid: "5d389d69-3a8f-4fa7-ace7-9c795e2aefd2"),
        "EX071": ExerciseMedia(videoGuid: "1d7761e7-7b3a-4b7b-860b-7363a62d6b86"),
        "EX073": ExerciseMedia(videoGuid: "0388633b-9dfb-44e2-b544-3adaadcf6912"),
        "EX075": ExerciseMedia(videoGuid: "1c8c9aa8-8110-4f97-bfad-5011ea5e1ab6"),
        "EX076": ExerciseMedia(videoGuid: "36d73934-becf-49b1-80fc-a0fdb1010cf5"),
        "EX077": ExerciseMedia(videoGuid: "d86d19a3-2b25-4fec-8a5e-426aaa9247a0"),
        "EX079": ExerciseMedia(videoGuid: "469329ad-292f-4aad-81b7-27d36799e6fb"),
        "EX080": ExerciseMedia(videoGuid: "d21a228a-bae3-4ead-bb2c-3a2729e7aeb0"),
        "EX081": ExerciseMedia(videoGuid: "f847fd56-7b94-45ef-b61f-be1dbdc3afa5"),
        "EX083": ExerciseMedia(videoGuid: "2b7a679a-702e-457e-b99b-a96b8605f567"),
        "EX085": ExerciseMedia(videoGuid: "5598b824-4d51-4a77-8caa-40936f289825"),
        "EX086": ExerciseMedia(videoGuid: "582f2907-e86f-4053-93e0-45ee7c9b3cf6"),
        "EX087": ExerciseMedia(videoGuid: "7c5a4222-12e8-4e36-a2a0-e2b6ea02b11d"),
        "EX089": ExerciseMedia(videoGuid: "5d57dec1-cfe2-4a22-a7ef-ad3c532d1339"),
        "EX090": ExerciseMedia(videoGuid: "6aac3f03-dc8a-4078-8a2a-d77b4cef6475"),
        "EX091": ExerciseMedia(videoGuid: "5a3c83f4-272e-483c-9113-1b878abde794"),
        "EX093": ExerciseMedia(videoGuid: "55484420-eaeb-4605-93d7-8888d46e3b15"),
        "EX094": ExerciseMedia(videoGuid: "d51817fc-e6e0-4bf3-a38f-a73abc5e7b32"),
        "EX095": ExerciseMedia(videoGuid: "6fc0a2d1-e6a0-4170-b418-a9cbf19c384a"),
        "EX097": ExerciseMedia(videoGuid: "fa7cfb1e-6971-4a0a-ab30-651528a29b0d"),
        "EX098": ExerciseMedia(videoGuid: "a51e2e26-ee15-4a09-8ca6-28aa50a048f3"),
        "EX099": ExerciseMedia(videoGuid: "f8f33754-56fd-41d3-a785-13d95b0d37c6"),
        "EX100": ExerciseMedia(videoGuid: "68c410f3-751c-4b24-a940-9d3ebe147755"),
        "EX101": ExerciseMedia(videoGuid: "53e9c2e3-c142-4ec0-803b-b7e0df899ff3"),
        "EX102": ExerciseMedia(videoGuid: "67b24139-82a2-4485-959a-5dc0aa25c37d"),
        "EX103": ExerciseMedia(videoGuid: "dbc2bc30-cd2b-463a-a341-df34e33f4069"),
        "EX104": ExerciseMedia(videoGuid: "00376de4-9f53-462d-8c19-48adbb1c2c9f"),
        "EX105": ExerciseMedia(videoGuid: "f960cb33-0587-4850-996b-53ac8fc008e5"),
        "EX106": ExerciseMedia(videoGuid: "201b5779-9483-4b38-838e-5dff16912541"),
        "EX108": ExerciseMedia(videoGuid: "2dc078b5-1b24-45b7-9562-80eb49482be3"),
        "EX109": ExerciseMedia(videoGuid: "e18734be-085d-4867-8046-e0678436a7a2"),
        "EX110": ExerciseMedia(videoGuid: "66aa114e-c4e9-4005-9ced-ff29cf297e2e"),
        "EX111": ExerciseMedia(videoGuid: "5491cb1b-7e3c-4500-8768-513f72e34cab"),
        "EX112": ExerciseMedia(videoGuid: "217567ba-c8f3-4582-9e49-f385b107848e"),
        "EX116": ExerciseMedia(videoGuid: "c9338023-13a2-4970-a18e-0f4ad140100f"),
        "EX117": ExerciseMedia(videoGuid: "9fb75c65-45e4-4771-9f25-0891cab2f635"),
        "EX118": ExerciseMedia(videoGuid: "e2df47b4-25cd-429f-873a-26aee9084785"),
        "EX121": ExerciseMedia(videoGuid: "1a834e37-9098-4f8f-8678-066fa71bfda4"),
        "EX122": ExerciseMedia(videoGuid: "95e8103c-c367-46c2-82f2-f0c8d7365291"),
        "EX123": ExerciseMedia(videoGuid: "d7967389-2d42-4d98-9c1b-f3312ff1d41a"),
        "EX124": ExerciseMedia(videoGuid: "5ebb1352-dddb-41ef-9822-df5ddbca3450"),
        "EX125": ExerciseMedia(videoGuid: "fb5cbb97-532b-4988-bea8-f19073f49b28"),
        "EX126": ExerciseMedia(videoGuid: "01e1aaff-bd3d-4fe0-a1a0-1b95241ab572"),
        "EX127": ExerciseMedia(videoGuid: "ac4b71d2-5066-4b4c-b321-30afd2a2b409"),
        "EX129": ExerciseMedia(videoGuid: "71bb6a61-e68b-4f85-9ce2-3d42c71adf40"),
        "EX130": ExerciseMedia(videoGuid: "131db21b-ac12-4a1c-8eee-7b2385fd0ba5"),
        "EX131": ExerciseMedia(videoGuid: "7520f7ae-02bd-4ce1-bf3c-ccf5050ff54f"),
        "EX132": ExerciseMedia(videoGuid: "9619b486-28d4-4446-9c33-668b118582b1"),
        "EX133": ExerciseMedia(videoGuid: "5cfa4700-8e22-4cff-b3f8-c802f066ca59"),
        "EX136": ExerciseMedia(videoGuid: "5ab5662b-2fe8-4f76-a060-8a0283aee420"),
        "EX137": ExerciseMedia(videoGuid: "74a16785-d9f3-4a6c-a44e-3a0566caf3ba"),
        "EX138": ExerciseMedia(videoGuid: "e783b464-9dd1-4f57-83ae-deab5ccf1ed7"),
        "EX139": ExerciseMedia(videoGuid: "5f31076c-be96-4c0b-a253-f2c42dd43401"),
    ]

    static func media(for exerciseId: String) -> ExerciseMedia? {
        return mapping[exerciseId]
    }

    static func videoURL(for exerciseId: String, libraryId: String) -> URL? {
        guard let media = mapping[exerciseId],
              media.mediaType == .video,
              let guid = media.guid else { return nil }
        return URL(string: "https://iframe.mediadelivery.net/embed/\(libraryId)/\(guid)")
    }

    static func imageURL(for exerciseId: String) -> URL? {
        guard let media = mapping[exerciseId],
              media.mediaType == .image,
              let filename = media.imageFilename else { return nil }
        return URL(string: "\(imageBaseURL)/\(filename)")
    }
}
