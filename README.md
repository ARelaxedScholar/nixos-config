### The New Goal: What "Proficient" Means in 7 Days (Template Edition)

*   Your machine boots from a ZFS-backed, impermanent configuration you control via a flake.
*   You understand the ZFS dataset layout and how snapshots provide both your impermanence and your safety net.
*   You can confidently add new software and services, knowing how to persist their required state across reboots.
*   You are fluent in the impermanent workflow: **Identify State -> Edit Code to Persist -> `nixos-rebuild switch --flake` -> Test -> Commit.**
*   You have used ZFS rollbacks to recover from a broken configuration.
*   You have a working `devShell` for one of your projects.

### The Tools of War

*   **A Separate Machine:** More critical than ever. This is your lifeline for reading docs and your ZFS cheat sheet.
*   **The NixOS Minimal Install ISO.**
*   **The URL to your chosen template.**
*   **Nerves of Steel.**

---

### The 7-Day Template Integration Program

**Day 0: The Blueprint Audit**

Your mission is to understand the machine you're about to build *before* you build it.
1.  **Full Backup:** Still non-negotiable. Do it.
2.  **Create Your Config Repo:** Create the empty `nixos-config` repo on GitHub.
3.  **Dissect the Template:** Clone the template repository *on another machine*. Open the `flake.nix` and the `disko.nix` files. Read them. You don't need to understand every line of Nix code, but you must answer these questions:
    *   What is the name of the ZFS pool (e.g., `zroot`)?
    *   What datasets is it creating? (You should see separate ones for `nix`, `persist`, `home`, etc.)
    *   Which dataset is it mounting to the root (`/`)?
    *   What is the *purpose* of each dataset?
4.  **The ZFS Kata:** This is your new rite of passage. Boot the NixOS ISO, but don't install yet. You will spend 30 minutes in the terminal learning the four commands that will save your life:
    *   `zpool status`: "Is my hardware okay?"
    *   `zfs list`: "What filesystems do I have?"
    *   `zfs list -t snapshot`: "What are my points in time?"
    *   `zfs rollback [snapshot_name]`: "Take me back!"
    Practice creating a dummy file, taking a snapshot, deleting the file, and rolling back to see it reappear. This muscle memory is your parachute.

**Day 1: The Ignition**

Your mission is to deploy the template and take ownership of the configuration.
1.  **Deploy:** Follow the template's instructions. This will likely involve a tool like `nixos-anywhere` which will connect to your machine via SSH from the live ISO, run Disko to partition the drive, and then install NixOS based on the flake.
2.  **First Boot & Verification:** It will boot into a working system. Log in. Your first commands are not `ls` or `cd`. They are:
    *   `sudo zpool status` (Verify the pool is `ONLINE`)
    *   `zfs list` (Verify the datasets match what you read in the template)
    *   `df -h` (See how the datasets are mounted)
3.  **Take Ownership:** Your system was built from the template's flake. Now you must make it yours.
    *   `cd /etc/nixos`
    *   This directory should be a git repo cloned from the template. Change the git remote to point to *your* new, empty `nixos-config` repo.
    *   `git push -u origin main --force`
    You have now captured the initial state of your machine in your own repository. This is your "Generation 0."

**Day 2: Taming the Beast (Persistence 101)**

Your mission is to make your first change and survive the consequences of impermanence.
1.  **The First Problem:** Your machine is perfect, but it has amnesia. Let's fix the most common issue: **NetworkManager's WiFi passwords.**
2.  **The Core Loop (Impermanent Edition):**
    *   **Investigate:** Why is the password gone? Because it's stored in `/etc/NetworkManager/system-connections/`. This path is on the root dataset, which gets wiped.
    *   **Find the Fix:** You need to persist this directory. You'll need to find the `impermanence` module options (or whatever persistence solution the template uses). You'll add something like `persist.directories = [ "/etc/NetworkManager/system-connections" ];` to your configuration.
    *   **Deploy:** Run `sudo nixos-rebuild switch --flake .#your-hostname`.
    *   **Test:** Reboot the machine. Connect to WiFi. Reboot again. Does it remember?
    *   **Commit:** If it works, `git commit -m "feat: Persist NetworkManager connections"` and `git push`.
3.  **Your Task:** Repeat this loop for your basic desktop needs. Get your browser to remember its profile. Get your display manager to remember your last session. Each one is a mini-quest that reinforces the core loop.

**Day 3: Claiming Your Home**

Your mission is to get your personal tools and dotfiles managed declaratively.
1.  **Analyze Home:** The template likely mounts a persistent ZFS dataset to `/home`. This means your files are safe, but your dotfiles aren't managed.
2.  **Integrate Home Manager:** The template should already have Home Manager installed as part of the flake. Your task is to find the `home.nix` file and start editing it.
3.  **First Change:** Pick one thing. Your `.gitconfig`. Don't copy the file; translate its contents into the `programs.git = { ... };` options in `home.nix`. Rebuild. Check if `git config --global user.name` is correct.
4.  **Install User Tools:** Add your essential CLI tools (`rg`, `fd`, `btop`, etc.) to `home.packages`. Rebuild, commit, push.

**Day 4: The Control Deck**

Your mission is to understand the Flake that runs your life and use it to build a dev environment.
1.  **Deconstruct the Flake:** Open your `flake.nix`. Identify the `inputs` (nixpkgs, home-manager, disko). Identify the `outputs` (your `nixosConfigurations`). See how the configuration is assembled from modules (`./configuration.nix`, `./disko.nix`, etc.).
2.  **Build a Dev Shell:** This is the same as the previous plan, and it's critical. Go into a project folder, create a *new* `flake.nix`, and define a `devShell` for it. Run `nix develop`. The feeling of creating a perfect, isolated environment for your code on top of your perfectly architected OS is the "aha!" moment.

**Day 5: The Safety Net**

Your mission is to break your system on purpose and recover gracefully using ZFS.
1.  **The "Oh No" Scenario:** Make a change you *know* will break something. A typo in a critical service name. An incorrect network configuration. Run `sudo nixos-rebuild switch --flake .#...`. It will build, but the resulting system will be broken.
2.  **The Recovery:** Reboot. In the bootloader menu, you will see a list of your NixOS "generations." Each one corresponds to a successful build. **These are linked to ZFS snapshots.**
3.  **Execute the Rollback:** Select an older, working generation to boot into. Your system is now temporarily running the old configuration.
4.  **Make it Permanent:** To revert the *code* and the *state*, log in, `cd /etc/nixos`, and `git revert [hash_of_broken_commit]`. Then run your rebuild command again. You have now used your Git history and your ZFS history together to effortlessly recover from a disaster.

**Day 6: Reality Bites**

Your mission is to handle secrets and hardware. This is unchanged, but even more important.
1.  **Secrets:** Set up `sops-nix`. With an impermanent root, you absolutely cannot just put a secret file somewhere and expect it to survive. `sops-nix` is the canonical way to solve this.
2.  **Hardware:** Get your Bluetooth, printer, or weird USB device working. This will teach you how to search for NixOS options and debug hardware-specific issues.

**Day 7: The Blueprint Review**

Your mission is to consolidate your knowledge.
1.  **Read Your Code:** Open your `nixos-config` repo on GitHub. Read every line of code you've added or changed. Add comments explaining *why* you persisted certain paths.
2.  **Read Your Snapshots:** Run `zfs list -t snapshot`. You should see a history of snapshots automatically created by NixOS on every successful build. You are looking at the timeline of your system's evolution.
3.  **Plan:** Your system is stable. What's next? Packaging a custom application? Hardening security? You're no longer a user; you're the architect.

This plan is more complex, but it gets you to a more powerful destination faster. You're leveraging the work of experts. Your job is to understand that work so you can make it your own.

Good luck. You'll need it.
