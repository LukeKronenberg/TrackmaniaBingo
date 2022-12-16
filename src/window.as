
namespace Window {
    bool Visible;
    bool JoinCodeVisible;
    bool RoomCodeVisible;
    string JoinCodeInput;

    void Render() {
        if (!Visible) return;
        UI::Begin(WindowName, Visible);

        if (!Permissions::PlayLocalMap()) {
            NoPermissions();
            UI::End();
            return;
        }

        if (Settings::DevMode) {
            DevControls();
            UI::Separator();
        }

        if (@Room != null && Room.InGame) {
            InGame();
            UI::End();
            return;
        }

        bool Disabled = false;
        if (StartCountdown > 0) {
            Countdown();
            Disabled = true;
        }
        if (Network::RequestInProgress) {
            Disabled = true;
        }
        if (Disabled) UI::BeginDisabled();

        if (@Room != null) {
            RoomView();
        } else {
            if (Config::StatusMessage != "") {
                UI::Text("\\$z" + Icons::InfoCircle + " \\$ff0" + Config::StatusMessage);
            }

            UI::BeginTabBar("Bingo_TabBar");

            if (UI::BeginTabItem(Icons::ShareSquareO + " Join Room")) {
                JoinTab();
                UI::EndTabItem();
            }

            if (UI::BeginTabItem(Icons::PlusSquare + " Create Room")) {
                CreateTab();
                UI::EndTabItem();
            }

            UI::PushStyleColor(UI::Col::Tab, vec4(0.1, 0.15, 0.3, 1.));
            UI::PushStyleColor(UI::Col::TabHovered, vec4(0.1, 0.2, 0.5, 1.));
            UI::PushStyleColor(UI::Col::TabActive, vec4(0.2, 0.3, 0.7, 1.));
            if (UI::BeginTabItem(Icons::InfoCircle + " About")) {
                InfoTab();
                UI::EndTabItem();
            }
            UI::PopStyleColor(3);

            UI::EndTabBar();
        }

        if (Disabled) UI::EndDisabled();
        UI::End();
    }

    void CreateTab() {
        RoomConfig.MaxPlayers = Math::Clamp(UI::InputInt("Room Size", RoomConfig.MaxPlayers), 2, 32);
        
        if (UI::BeginCombo("Map Selection", stringof(RoomConfig.MapSelection))) {
            if (UI::Selectable(stringof(MapMode::TOTD), RoomConfig.MapSelection == MapMode::TOTD)) {
                RoomConfig.MapSelection = MapMode::TOTD;
            }

            if (UI::Selectable(stringof(MapMode::MXRandom), RoomConfig.MapSelection == MapMode::MXRandom)) {
                RoomConfig.MapSelection = MapMode::MXRandom;
            }

            if (UI::Selectable(stringof(MapMode::Mappack), RoomConfig.MapSelection == MapMode::Mappack)) {
                RoomConfig.MapSelection = MapMode::Mappack;
            }

            UI::EndCombo();
        }

        if (RoomConfig.MapSelection == MapMode::Mappack) {
            RoomConfig.MappackId = UI::InputInt("TMX Mappack ID", RoomConfig.MappackId, 0);
        }

        if (UI::BeginCombo("Target Medal", stringof(RoomConfig.TargetMedal))) {
            if (UI::Selectable(stringof(Medal::Author), RoomConfig.TargetMedal == Medal::Author)) {
                RoomConfig.TargetMedal = Medal::Author;
            }

            if (UI::Selectable(stringof(Medal::Gold), RoomConfig.TargetMedal == Medal::Gold)) {
                RoomConfig.TargetMedal = Medal::Gold;
            }

            if (UI::Selectable(stringof(Medal::Silver), RoomConfig.TargetMedal == Medal::Silver)) {
                RoomConfig.TargetMedal = Medal::Silver;
            }
            if (UI::Selectable(stringof(Medal::Bronze), RoomConfig.TargetMedal == Medal::Bronze)) {
                RoomConfig.TargetMedal = Medal::Bronze;
            }
            if (UI::Selectable(stringof(Medal::None), RoomConfig.TargetMedal == Medal::None)) {
                RoomConfig.TargetMedal = Medal::None;
            }

            UI::EndCombo();
        }

        if (!Config::CanPlay) UI::BeginDisabled();
        if (UI::Button("Create Room")) {
            startnew(Network::CreateRoom);
        }
        if (!Config::CanPlay) UI::EndDisabled();
    }

    void JoinTab() {
        JoinCodeInput = UI::InputText("Room Code", JoinCodeInput, false, UI::InputTextFlags::CharsUppercase | (JoinCodeVisible? 0 : UI::InputTextFlags::Password));
        UI::SameLine();
        JoinCodeVisible = UI::Checkbox("Show code", JoinCodeVisible);

        if (!Config::CanPlay) UI::BeginDisabled();
        if (UI::Button("Join Room") && Room.JoinCode.Length >= 6) {
            startnew(Network::JoinRoom);
        }
        if (!Config::CanPlay) UI::EndDisabled();
    }

    void InfoTab() {
        UI::PushFont(Font::Header);
        UI::Text("Trackmania Bingo");
        UI::PopFont();
        UI::Text(Icons::Plug + " Plugin created by \\$ff0TheGeekid");
        UI::Text(Icons::Github + " Source code:");
        UI::SameLine();
        UI::Markdown("[Geekid812/TrackmaniaBingo](https://github.com/Geekid812/TrackmaniaBingo)");
        UI::Text(Icons::Bug + " Bug tracker:");
        UI::SameLine();
        UI::Markdown("[Report an Issue](https://github.com/Geekid812/TrackmaniaBingo/issues)");
        UI::Text(Icons::DiscordAlt + " Discord server:");
        UI::SameLine();
        UI::Markdown("[Trackmania Bingo](https://discord.gg/pJbeqptsEa)");
        UI::Text("");

        Changelog();
        UI::Text("");

        UI::Markdown("## How to play");
        UI::TextWrapped("In this mode, two or more teams compete be the first to complete a row, column or diagonal on the game board. Each cell on this board corresponds to a track that players can claim for their team by achieving a specific medal on that track.");
        UI::TextWrapped("Once a track has been claimed, in order to reclaim it, other teams must beat the time that was set on that track. Try to play strategically to be the first team to achieve a bingo!");
        UI::Text("Good luck and have fun!");
    }

    void RoomView() {
        UI::Text(Room.HostName + (Room.HostName.EndsWith("s") ? "'": "'s") + " Bingo Room - " + Room.Players.Length + "/" + Room.Config.MaxPlayers + " players");
        UI::SameLine();
        UIColor::DarkRed();
        if (UI::Button(Icons::Kenney::Exit + " Leave")) {
            startnew(Network::LeaveRoom);
        }
        UIColor::Reset();

        if (Room.LocalPlayerIsHost) {
            UIColor::DarkGreen();
            bool StartDisabled = (Room.Players.Length < 2 && !Settings::DevMode) || Room.MapsLoadingStatus != LoadStatus::LoadSuccess;
            if (StartDisabled) UI::BeginDisabled();
            
            UI::SameLine();
            if (UI::Button(Icons::PlayCircleO + " Start")) {
                startnew(Network::StartGame);
            }
            if (StartDisabled) UI::EndDisabled();
            UIColor::Reset();
        }
        if (Room.MapsLoadingStatus != LoadStatus::LoadSuccess) {
            if (Room.MapsLoadingStatus == LoadStatus::Loading) {
                UI::Text("\\$ff0" + Icons::HourglassHalf + " \\$zFetching maps from TMX...");
            } else {
                UI::Text("\\$ff0" + Icons::ExclamationTriangle + " \\$ff6Maps could not be loaded from TMX. The game cannot be started.");
            }
        } else {
            UI::Text(""); // Blank space to avoid layout shifts
        }

        UI::Text("\\$ff0Map Selection: \\$z" + stringof(Room.Config.MapSelection));
        UI::Text("\\$ff0Target Medal: \\$z" + stringof(Room.Config.TargetMedal));
        UI::Text("\\$ff0Time Limit: \\$z" + (Room.Config.MinutesLimit == 0 ? "Unlimited" : tostring(Room.Config.MinutesLimit) + " minutes"));

        UI::Text("\\$ff0Room Code: \\$z" + (RoomCodeVisible ? Room.JoinCode : "######"));
        UI::SameLine();
        if (UI::Button(RoomCodeVisible ? "Hide" : "Show")) RoomCodeVisible = !RoomCodeVisible;
        UI::SameLine();
        if (UI::Button(Icons::Clipboard + " Copy")) IO::SetClipboard(Room.JoinCode);

        UI::BeginTable("Bingo_TeamTable", Room.Teams.Length + (Room.MoreTeamsAvaliable()? 1 : 0));

        for (uint i = 0; i < Room.Teams.Length; i++) {
            UI::TableNextColumn();
            Team@ Team = Room.Teams[i];
            UIColor::Custom(UIColor::Brighten(Team.Color, 0.75));
            int teamIdXdd = Team.Id;
            if (UI::Button("Join##" + Team.Id)) startnew(function(ref@ team) { Network::JoinTeam(cast<Team>(team)); }, Team);
            UI::SameLine();
            UI::Text("\\$" + UIColor::GetHex(Team.Color) + Team.Name);
            UIColor::Reset();
        }

        if (Room.MoreTeamsAvaliable()) {
            UI::TableNextColumn();
            if (UI::Button(Icons::PlusSquare + " Create team")) {
                startnew(Network::CreateTeam);
            }
        }

        uint RowIndex = 0;
        while (true){
            // Iterate forever until no players in any team remain
            UI::TableNextRow();
            uint FinishedTeams = 0;
            for (uint i = 0; i < Room.Teams.Length; i++){
                // Iterate through all teams
                UI::TableNextColumn();
                Player@ Player = PlayerCell(Room.Teams[i], RowIndex);
                if (Player is null) { // No more players in this team
                    FinishedTeams += 1;
                    continue;
                }
                else {
                    UI::Text((Player.IsSelf ? "\\$ff8" : "") + (RowIndex + 1) + ". " + Player.Name);
                }
            }
            if (FinishedTeams == Room.Teams.Length) break;
            RowIndex += 1;
        }
        UI::EndTable();
    }

    void Countdown() {
        UI::PushFont(Font::Header);
        int SecondsRemaining = StartCountdown / 1000 + 1;
        UI::Text("Game starting in " + SecondsRemaining + "...");
        UI::PopFont();
        UI::NewLine();
        UI::Separator();
    }

    void InGame() {
        UI::Text("A game is already running! Close this window and keep playing!");
        if (UI::Button(Icons::Kenney::Exit + " Leave Game")) {
            startnew(Network::LeaveRoom);
        }
    }

    void NoPermissions() {
        UI::TextWrapped("Unfortunately, you do not have permission to play this gamemode.");
        UI::TextWrapped("Playing Bingo requires having at least \\$999Standard Access\\$z, which you do not seem to have. Sorry!");
        UI::TextWrapped("If you believe this is a mistake, make sure to restart your game and check your internet connection.");
    }

    void DevControls() {
        UIColor::Cyan();
        if (UI::Button(Icons::Signal + " Force Disconnect")) {
            startnew(Network::OnDisconnect);
        }
        UIColor::Reset();
    }
}

// Helper function to build the table
Player@ PlayerCell(Team team, int index) {
    int Count = 0;
    for (uint i = 0; i < Room.Players.Length; i++) {
        auto Player = Room.Players[i];
        if (Player.Team == team) {
            if (Count == index) return Player;
            else Count += 1;
        }
    }
    return null;
}
