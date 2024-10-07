use std::process::Command;
use std::{thread, time::Duration};

fn main() {
    //TODO grab application list and allow user to select using clap

    let application_list = Command::new("flatpak")
        .arg("list")
        .output()
        .expect("Failed to execute flatpak list");

    let application = "com.brave.Browser";

    //TODO: do not depend on flatpak
    Command::new("flatpak")
        .arg("run")
        .arg(application)
        .spawn()
        .expect("Failed to launch application");

    //HACK: make sure app has launched
    //thread::sleep(Duration::from_secs(5));
    //TODO grab wmctrl -l then check the id that has a name similar to the application selected
    //Command::new("wmctrl")
    //    .args(["-r", application, "-b", "add,fullscreen"])
    //.output()
    //.expect("Failed to set the window to fullscreen");
}
