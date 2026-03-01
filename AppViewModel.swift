import Foundation
import SwiftUI

enum JourneyStep: Int, CaseIterable {
    case intro
    case security
    case bingo
    case calm
    case finish
}

struct BingoItem: Identifiable, Equatable {
    let id = UUID()
    let imageName: String
    let title: String
    let info: String
    let tip: String
    var isFound: Bool = false

    static func == (lhs: BingoItem, rhs: BingoItem) -> Bool { lhs.id == rhs.id }
}

@MainActor
final class AppViewModel: ObservableObject {
    // Navigation
    @Published var step: JourneyStep = .intro

    // Bingo state
    @Published var items: [BingoItem] = [
        BingoItem(imageName: "Passport", title: "Passport",
                  info: "Your travel ID. It proves who you are.",
                  tip: "Keep it safe and easy to reach."),
        BingoItem(imageName: "Suitcase", title: "Suitcase",
                  info: "Holds your clothes and travel items.",
                  tip: "Look for a tag so you can recognize it."),
        BingoItem(imageName: "Airplane", title: "Airplane",
                  info: "A big machine that flies using wings and engines.",
                  tip: "Wings help lift the plane up."),
        BingoItem(imageName: "Boarding Pass", title: "Boarding Pass",
                  info: "Your ticket to enter the plane.",
                  tip: "It shows your seat and gate number."),
        BingoItem(imageName: "Gate Sign", title: "Gate Sign",
                  info: "Shows where your flight will board.",
                  tip: "Match the gate with your boarding pass."),
        BingoItem(imageName: "Departure Screen", title: "Departure Screen",
                  info: "Shows flight times, gates, and updates.",
                  tip: "Check it if your gate changes."),
        BingoItem(imageName: "Pilot", title: "Pilot",
                  info: "The person who flies the airplane.",
                  tip: "Pilots follow safety rules and check the plane."),
        BingoItem(imageName: "Coffee Shop", title: "Coffee Shop",
                  info: "A place to buy drinks and snacks.",
                  tip: "Snack time helps during long waits."),
        BingoItem(imageName: "Security Check", title: "Security Check",
                  info: "A safety step before going to the gates.",
                  tip: "Follow the signs and listen to staff.")
    ]

    @Published var selectedIndex: Int? = nil
    @Published var showBingo: Bool = false
    @Published var winningIndices: Set<Int> = []
    @Published var bingoAcknowledged: Bool = false

    var foundCount: Int { items.filter { $0.isFound }.count }
    var bingoAchieved: Bool { winningLine(in: items) != nil }

    // Navigation actions
    func goToSecurity() { step = .security }
    func goToBingo() { step = .bingo }
    func goToCalm() { step = .calm }
    func goToFinish() { step = .finish }
    func restart() { step = .intro }

    // Bingo actions
    func selectItem(_ index: Int) { if !showBingo { selectedIndex = index } }

    func toggleFound(at index: Int) {
        guard items.indices.contains(index) else { return }
        items[index].isFound.toggle()
        onItemsChanged()
    }

    func resetBingo() {
        for i in items.indices { items[i].isFound = false }
        showBingo = false
        winningIndices.removeAll()
        selectedIndex = nil
        bingoAcknowledged = false
    }

    func randomizeBingo() {
        items.shuffle()
        showBingo = false
        winningIndices.removeAll()
        selectedIndex = nil
        bingoAcknowledged = false
    }

    func onItemsChanged() {
        if bingoAcknowledged, winningLine(in: items) == nil {
            bingoAcknowledged = false
        }
        triggerBingoIfNeeded(closeSheet: false)
    }

    func triggerBingoIfNeeded(closeSheet: Bool) {
        if showBingo { return }
        if !winningIndices.isEmpty { return }
        if bingoAcknowledged { return }
        if let win = winningLine(in: items) {
            winningIndices = Set(win)
            showBingo = true
            if closeSheet { selectedIndex = nil }
        }
    }

    func winningLine(in items: [BingoItem]) -> [Int]? {
        guard items.count == 9 else { return nil }
        let found = items.map { $0.isFound }
        let lines = [
            [0,1,2],[3,4,5],[6,7,8],
            [0,3,6],[1,4,7],[2,5,8],
            [0,4,8],[2,4,6]
        ]
        for line in lines where line.allSatisfy({ found[$0] }) { return line }
        return nil
    }
}
