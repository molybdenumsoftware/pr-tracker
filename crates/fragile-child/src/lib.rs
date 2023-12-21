/// A newtype over [`std::process::Child`] that kills the child on drop.
#[derive(Debug)]
pub struct FragileChild(std::process::Child);

impl FragileChild {
    pub fn kill(&mut self) -> std::io::Result<()> {
        self.0.kill()
    }

    pub fn wait(&mut self) -> std::io::Result<std::process::ExitStatus> {
        self.0.wait()
    }
}

pub trait SpawnFragileChild {
    fn spawn_fragile(&mut self) -> std::io::Result<FragileChild>;
}

impl SpawnFragileChild for std::process::Command {
    fn spawn_fragile(&mut self) -> std::io::Result<FragileChild> {
        Ok(FragileChild(self.spawn()?))
    }
}

impl Drop for FragileChild {
    fn drop(&mut self) {
        let Self(child) = self;
        child.kill().unwrap();
        child.wait().unwrap();
    }
}
