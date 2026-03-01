import SwiftUI
import AVKit

// MARK: - Shared Button Style (Fix sizes everywhere)

private struct PrimaryButtonStyle: ViewModifier {
    var background: Color

    func body(content: Content) -> some View {
        content
            .font(.headline)
            .frame(maxWidth: .infinity)
            .frame(height: 56)                 //  ثابت
            .contentShape(Rectangle())
            .foregroundStyle(Color.black)
            .background(background)
            .opacity(1.0)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.black.opacity(0.08), lineWidth: 1)
            )
            .scaleEffect(1.0)
    }
}

private struct SecondaryButtonStyle: ViewModifier {
    var background: Color

    func body(content: Content) -> some View {
        content
            .font(.headline)
            .frame(maxWidth: .infinity)
            .frame(height: 50)                 //  ثابت للثانوي
            .contentShape(Rectangle())
            .foregroundStyle(Color.black)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.black.opacity(0.08), lineWidth: 1)
            )
    }
}

extension View {
    func primaryButton(background: Color) -> some View {
        modifier(PrimaryButtonStyle(background: background))
    }

    func secondaryButton(background: Color) -> some View {
        modifier(SecondaryButtonStyle(background: background))
    }
}

// MARK: - App Background

private struct AppBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        ZStack {
            Image("Background")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            Color.black.opacity(0.08)
                .ignoresSafeArea()

            content
        }
    }
}

extension View {
    func appBackground() -> some View {
        self.modifier(AppBackgroundModifier())
    }
}

// MARK: - App Root

struct ContentView: View {
    @StateObject private var vm = AppViewModel()

    var body: some View {
        NavigationStack {
            Group {
                switch vm.step {
                case .intro:
                    SplashVideoView()
                case .security:
                    SecurityScreen()
                case .bingo:
                    BingoMissionScreen()
                case .calm:
                    CalmScreen()
                case .finish:
                    FinishScreen()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .animation(.easeInOut(duration: 0.25), value: vm.step)
        }
        .environmentObject(vm)
        .appBackground()
        .preferredColorScheme(.light)
    }
}

// MARK: - 1) Intro (unused currently, kept as-is)

struct IntroScreen: View {
    @EnvironmentObject var vm: AppViewModel

    var body: some View {
        VStack(spacing: 18) {
            Spacer()

            Text("Little Explorer")
                .font(.largeTitle).bold()

            Text("Today you’re an Airport Explorer.\nLet’s make waiting time easier and calmer.")
                .font(.body)
                .foregroundStyle(Color.gray)
                .multilineTextAlignment(.center)

            Spacer()

            Button {
                vm.goToSecurity()
            } label: {
                Text("Start Journey")
            }
            .primaryButton(background: Color.blue.opacity(0.22))
            .accessibilityLabel("Start Journey")
            .accessibilityHint("Begin the airport explorer journey")
            .padding(.bottom, 8)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .appBackground()
    }
}

// MARK: - 2) Security

struct SecurityScreen: View {
    @EnvironmentObject var vm: AppViewModel

    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            VStack(spacing: 16) {
                Image("Security Check")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 100)

                Text("Security Check")
                    .font(.title).bold()

                Text("Security helps keep everyone safe.\nWe follow the signs and listen to staff.")
                    .foregroundStyle(Color.gray)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 4)

                Button {
                    vm.goToBingo()
                } label: {
                    Text("I’m ready")
                }
                .primaryButton(background: Color.green.opacity(0.22))
                .accessibilityLabel("I'm ready")
                .accessibilityHint("Proceed to the Bingo mission")
            }
            .padding(.horizontal, 20)

            Spacer()
        }
        .padding(.vertical, 12)
        .appBackground()
    }
}

// MARK: - 3) Bingo Mission

struct BingoMissionScreen: View {
    @EnvironmentObject var vm: AppViewModel

    private let gridColumns: [GridItem] =
        Array(repeating: GridItem(.flexible(), spacing: 18), count: 3)

    private var foundCount: Int { vm.foundCount }
    private var bingoAchieved: Bool { vm.bingoAchieved }

    var body: some View {
        VStack(spacing: 12) {
            header
            grid
            status
            Spacer()
            controls
            nextButton
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .padding(.top, 10)
        .appBackground()
        .sheet(
            isPresented: Binding(
                get: { vm.selectedIndex != nil },
                set: { if !$0 { vm.selectedIndex = nil } }
            )
        ) {
            let idx = vm.selectedIndex ?? 0
            ItemInfoSheet(
                item: vm.items[idx],
                isFound: $vm.items[idx].isFound,
                onClose: { vm.selectedIndex = nil },
                onAfterToggle: { vm.triggerBingoIfNeeded(closeSheet: true) }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .onChange(of: vm.items) { _ in
            vm.onItemsChanged()
        }
        .overlay {
            if vm.showBingo && !vm.winningIndices.isEmpty {
                BingoOverlay(onClose: {
                    vm.showBingo = false
                    vm.winningIndices.removeAll()
                    vm.bingoAcknowledged = true
                })
            }
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            Text("🔎 Explorer Mission")
                .font(.title2).bold()
            Text("Make a BINGO line: 3 in a row.")
                .foregroundStyle(Color.gray)
            Text("Found \(foundCount)/\(vm.items.count)")
                .font(.headline)

            ProgressView(value: Double(foundCount), total: Double(vm.items.count))
                .progressViewStyle(.linear)
                .tint(.green)
                .padding(.top, 4)
                .accessibilityLabel("Progress")
                .accessibilityValue("\(foundCount) of \(vm.items.count) found")
        }
        .padding(.bottom, 6)
    }

    private var grid: some View {
        LazyVGrid(columns: gridColumns, spacing: 18) {
            ForEach(vm.items.indices, id: \.self) { index in
                let item = vm.items[index]
                let isWinning = vm.winningIndices.contains(index)

                Button {
                    if !vm.showBingo { vm.selectItem(index) }
                } label: {
                    VStack(spacing: 10) {
                        Image(item.imageName)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 92)
                            .padding(.horizontal, 8)

                        Text(item.title)
                            .font(.footnote.weight(.medium))
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .minimumScaleFactor(0.8)
                            .padding(.horizontal, 4)
                    }
                    .frame(maxWidth: .infinity, minHeight: 150)
                    .padding(.vertical, 10)
                    .background(
                        item.isFound
                        ? (isWinning ? Color.green.opacity(0.36) : Color.green.opacity(0.24))
                        : Color.white.opacity(0.75)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(
                                item.isFound
                                ? (isWinning ? Color.green : Color.green.opacity(0.6))
                                : Color.black.opacity(0.08),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
                }
                .buttonStyle(.plain)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(item.title), \(item.isFound ? "Found" : "Not found")")
                .accessibilityHint("Double tap to view details")
                .disabled(vm.showBingo)
            }
        }
        .padding(.top, 10)
    }

    private var status: some View {
        Group {
            if bingoAchieved {
                Text("🎉 BINGO unlocked!")
                    .font(.headline)
                    .padding(.top, 6)
            }
        }
    }

    private var controls: some View {
        HStack(spacing: 12) {
            Button("Reset") { vm.resetBingo() }
                .secondaryButton(background: Color.gray.opacity(0.12))
                .disabled(vm.showBingo)

            Button("Randomize") { vm.randomizeBingo() }
                .secondaryButton(background: Color.blue.opacity(0.18))
                .disabled(vm.showBingo)
        }
    }

    private var nextButton: some View {
        Button {
            vm.goToCalm()
        } label: {
            Text(bingoAchieved ? "Next" : "Skip for now")
        }
        .primaryButton(background: Color.green.opacity(0.22))
        .accessibilityLabel(bingoAchieved ? "Next" : "Skip for now")
        .accessibilityHint(bingoAchieved ? "Continue to Calm Mode" : "Skip Bingo and continue to Calm Mode")
        .padding(.top, 6)
        .disabled(vm.showBingo)
    }
}

// MARK: - Item Sheet

struct ItemInfoSheet: View {
    let item: BingoItem
    @Binding var isFound: Bool
    let onClose: () -> Void
    let onAfterToggle: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            Image(item.imageName)
                .resizable()
                .scaledToFit()
                .frame(height: 120)
                .padding(.bottom, 6)

            Text(item.title)
                .font(.title2).bold()

            VStack(alignment: .leading, spacing: 10) {
                Text("Info").font(.headline)
                Text(item.info).foregroundStyle(Color.gray)

                Text("Tip").font(.headline).padding(.top, 4)
                Text(item.tip).foregroundStyle(Color.gray)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                isFound.toggle()
                onAfterToggle()
            } label: {
                Text(isFound ? "Mark as Not Found" : "Mark as Found")
            }
            .primaryButton(background: isFound ? Color.gray.opacity(0.14) : Color.white.opacity(0.55))

            Button("Close") { onClose() }
                .font(.headline)
                .padding(.top, 2)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
    }
}

// MARK: - Bingo Overlay

struct BingoOverlay: View {
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            Text("🎉 BINGO!")
                .font(.largeTitle).bold()
            Text("Great spotting! You made a line.")
                .font(.subheadline)
                .foregroundStyle(Color.gray)

            Button("Continue") { onClose() }
                .secondaryButton(background: Color.green.opacity(0.22))
                .frame(maxWidth: 220)
                .padding(.top, 6)
        }
        .padding(18)
        .frame(maxWidth: 320)
        .background(Color.white.opacity(0.98))
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .shadow(radius: 18)
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(Color.gray.opacity(0.18), lineWidth: 1)
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.25).ignoresSafeArea())
    }
}

// MARK: - 4) Calm Mode

struct CalmScreen: View {
    @EnvironmentObject var vm: AppViewModel
    @State private var secondsLeft = 20
    @State private var inhalePhase = true
    @State private var tickingTask: Task<Void, Never>? = nil

    var body: some View {
        VStack(spacing: 14) {
            Spacer()

            Text("🌬️")
                .font(.system(size: 60))

            Text("Calm Mode")
                .font(.title).bold()

            Text("Takeoff can feel loud.\nLet’s breathe together for \(secondsLeft)s.")
                .foregroundStyle(Color.gray)
                .multilineTextAlignment(.center)

            BreathingCircle()
                .frame(width: 140, height: 140)
                .padding(.top, 6)

            Text(inhalePhase ? "Inhale" : "Exhale")
                .font(.headline)
                .foregroundStyle(Color.gray)
                .accessibilityLabel(inhalePhase ? "Inhale" : "Exhale")

            Spacer()

            Button {
                stopTimer()
                vm.goToFinish()
            } label: {
                Text("Done")
            }
            .primaryButton(background: Color.gray.opacity(0.12))
            .accessibilityLabel("Done")
            .accessibilityHint("Finish calming and proceed to the reward")
            .padding(.bottom, 8)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .appBackground()
        .onAppear { startTimer() }
        .onDisappear { stopTimer() }
    }

    @MainActor
    private func startTimer() {
        secondsLeft = 20
        tickingTask?.cancel()
        tickingTask = Task { @MainActor in
            while secondsLeft > 0 {
                try? await Task.sleep(for: .seconds(1))
                secondsLeft -= 1
                inhalePhase = (secondsLeft % 6) >= 3
            }
            stopTimer()
            vm.goToFinish()
        }
    }

    @MainActor
    private func stopTimer() {
        tickingTask?.cancel()
        tickingTask = nil
    }
}

struct BreathingCircle: View {
    @State private var breatheIn = false

    var body: some View {
        Circle()
            .opacity(0.18)
            .scaleEffect(breatheIn ? 1.0 : 0.65)
            .overlay(
                Circle()
                    .opacity(0.12)
                    .scaleEffect(breatheIn ? 0.65 : 1.0)
            )
            .onAppear {
                withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                    breatheIn.toggle()
                }
            }
    }
}

// MARK: - 5) Finish

struct FinishScreen: View {
    @EnvironmentObject var vm: AppViewModel
    @State private var clapPulse = false

    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            ZStack(alignment: .center) {
                Image(systemName: "hands.clap.fill")
                    .font(.system(size: 64, weight: .semibold))
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(Color.primary, Color.yellow.opacity(0.85))
                    // إن رغبت بالإبقاء على النبض الخفيف:
                    .scaleEffect(clapPulse ? 1.06 : 0.94)
                    .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: clapPulse)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .accessibilityLabel("Applause")
            .onAppear { clapPulse = true } // د النبض
            Text("You did it!")
                .font(.largeTitle).bold()

            Text("You’re now a Junior Traveler.\nWaiting time is an adventure — not stress.")
                .foregroundStyle(Color.gray)
                .multilineTextAlignment(.center)

            Spacer()

            Button {
                vm.restart()
            } label: {
                Text("Restart")
            }
            .primaryButton(background: Color.blue.opacity(0.22))
            .accessibilityLabel("Restart")
            .accessibilityHint("Start the journey again from the beginning")
            .padding(.bottom, 8)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .appBackground()
    }
}

// MARK: - Splash (Fixed button sizing + layout)

struct SplashVideoView: View {
    @EnvironmentObject var vm: AppViewModel

    var body: some View {
        ZStack {
            Image("Background")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            Color.black.opacity(0.06).ignoresSafeArea()

            VStack(spacing: 14) {
                Spacer(minLength: 40)

                VStack(spacing: 10) {
                    Text("Junior Traveler")
                        .font(.largeTitle).bold()
                        .multilineTextAlignment(.center)

                    Text("Turn airport waiting into a calm little adventure.")
                        .font(.body)
                        .foregroundStyle(Color.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)

                    HStack(spacing: 10) {
                        FeaturePill(text: "Bingo")
                        FeaturePill(text: "Calm")
                        FeaturePill(text: "Reward")
                    }
                    .padding(.top, 4)
                }
                .frame(maxWidth: 520)
                .padding(.horizontal, 20)

                Spacer()

                VStack(spacing: 12) {
                    HStack(spacing: 6) {
                        Dot(active: true)
                        Dot(active: false)
                        Dot(active: false)
                        Dot(active: false)
                    }

                    Button {
                        vm.goToSecurity()
                    } label: {
                        Text("Start Journey")
                    }
                    .primaryButton(background: Color.blue.opacity(0.22))
                }
                .frame(maxWidth: 520)
                .padding(.horizontal, 20)
                .padding(.bottom, 34)
            }
        }
    }
}

// MARK: - Small UI Helpers

private struct FeaturePill: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.footnote.weight(.semibold))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.60))
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(Color.black.opacity(0.06), lineWidth: 1)
            )
    }
}

private struct Dot: View {
    let active: Bool
    var body: some View {
        Circle()
            .frame(width: 7, height: 7)
            .foregroundStyle(Color.black)
            .opacity(active ? 0.40 : 0.15)
    }
}

#Preview("Splash") {
    SplashVideoView()
        .environmentObject(AppViewModel())
}
#Preview("Security") {
    SecurityScreen()
        .environmentObject(AppViewModel())
}

#Preview("Bingo") {
    BingoMissionScreen()
        .environmentObject(AppViewModel())
}

#Preview("Calm") {
    CalmScreen()
        .environmentObject(AppViewModel())
}

#Preview("Finish") {
    FinishScreen()
        .environmentObject(AppViewModel())
}

 
