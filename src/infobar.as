
namespace InfoBar {
    // Margin between the board and the "info bar", in pixels
    const int BoardMargin = 8;

    bool SettingsOpen;

    void Render() {
        if (@Room == null || !Room.InGame) return;
        
        auto team = Room.GetSelf().Team;
        UI::Begin("Board Information", UI::WindowFlags::NoTitleBar | UI::WindowFlags::AlwaysAutoResize | UI::WindowFlags::NoScrollbar | UI::WindowFlags::NoMove);

        UI::PushFont(Font::MonospaceBig);
        string colorPrefix = "";
        uint64 referenceTime = Time::Now;
        if (Room.EndState.HasEnded()) {
            colorPrefix = "\\$fb0";
            referenceTime = Room.EndState.EndTime;
        }

        // Time since the game has started (post-countdown), in milliseconds
        uint64 stopwatchTime = referenceTime - Room.StartTime - CountdownTime;
        // If playing with a time limit, timer counts down to 0
        if (Room.Config.MinutesLimit != 0) stopwatchTime = Math::Max(Room.Config.MinutesLimit * 60 * 1000 - stopwatchTime, 0);
        
        UI::Text(colorPrefix + Time::Format(stopwatchTime, false, true, true));
        UI::PopFont();

        UI::PushFont(Font::Regular);
        UI::SameLine();
        UI::PushStyleVar(UI::StyleVar::FramePadding, vec2(6, 5));
        string MapListText = "Open Map List";
        if (MapList::Visible) MapListText = "Close Map List";
        UIColor::Custom(team.Color);
        if (UI::Button(MapListText)) {
            MapList::Visible = !MapList::Visible;
        }
        UIColor::Reset();

        UIColor::Gray();
        if (Room.EndState.HasEnded()) {
            UI::SameLine();
            if (UI::Button("Exit")) {
                Network::Reset();
            }
        }
        UIColor::Reset();
        UI::PopStyleVar();

        if (!Room.EndState.HasEnded()) {
            RunResult@ RunToBeat = Playground::GetCurrentTimeToBeat();
            Team@ ClaimedTeam = Room.GetCurrentMap().ClaimedTeam;
            if (@RunToBeat != null) {
                if (RunToBeat.Time != -1 && (@ClaimedTeam == null || ClaimedTeam != team)) {
                    UI::Text("Time to beat: " + RunToBeat.Display());
                } else if (RunToBeat.Time != -1) {
                    UI::Text("Your team's time: " + RunToBeat.Display());
                } else {
                    UI::Text("Complete this map to claim it!");
                }
            }
        }
        UI::PopFont();

        vec2 WindowSize = UI::GetWindowSize();
        UI::SetWindowPos(vec2(int(Board::Position.x) + (int(Board::BoardSize) - WindowSize.x) / 2, int(Board::Position.y) + int(Board::BoardSize) + BoardMargin), UI::Cond::Always);
        UI::End();
    }
}