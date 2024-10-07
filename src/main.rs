use inquire::Select;
use serde::Serialize;
use std::process::Command;
use std::str;

fn main() {
    #[derive(Serialize, Debug)]
    struct FlatpakApp {
        name: String,
        application_id: String,
        version: String,
        branch: String,
        installation: String,
    }

    let command_output = Command::new("flatpak")
        .arg("list")
        .output()
        .expect("Failed to execute flatpak list");

    let output_str = str::from_utf8(&command_output.stdout).expect("Invalid utf8");

    //TODO: loop through apps and push apps into apps vec
    let mut apps: Vec<FlatpakApp> = Vec::new();

    //TODO: allow user to select an app from the apps vec! using inquire

    // TODO: Launch app selected by the user
    // Command::new("flatpak")
    //     .arg("run")
    //     .arg(application)
    //     .spawn()
    //     .expect("Failed to launch application");

    //TODO: grab wmctrl -l then check the id that has a name similar to the application selected
    //Command::new("wmctrl")
    //    .args(["-r", application, "-b", "add,fullscreen"])
    //.output()
    //.expect("Failed to set the window to fullscreen");
}
