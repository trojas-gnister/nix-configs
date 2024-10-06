use std::process::Command;
use std::{thread, time::Duration};

fn main() {
    //TODO: Grab applications from user and provide as a selectable list using clap 
    let application = "com.brave.Browser";
    
    //TODO: do not depend on flatpak
    Command::new("flatpak")
        .arg("run")
        .arg(application)
        .spawn()
        .expect("Failed to launch application");

    //HACK: make sure app has launched
    thread::sleep(Duration::from_secs(5));

    
}
