# Using SSH Keys for GitHub Access on Euler

## 1. Check for your SSH directory (create it if needed)

After logging into Euler, list hidden directories in your home directory:

```bash
ls -a ~
```

If you see a directory named `.ssh`, enter it:

```bash
cd ~/.ssh
```

If `.ssh` is not listed, create it and then enter it:

```bash
mkdir ~/.ssh
chmod 700 ~/.ssh
cd ~/.ssh
```

This ensures you are working in the standard location SSH expects and that the permissions are correct.

## 2. Create an SSH key (on Euler)

From inside the `.ssh` directory, run:

```bash
ssh-keygen -t ed25519 -C "euler"
```

When prompted:

- **File location:** press Enter (default: `~/.ssh/id_ed25519`)
- **Passphrase:** optional (adds extra security)

This creates:

- `~/.ssh/id_ed25519` → private key (keep secret)
- `~/.ssh/id_ed25519.pub` → public key (safe to share)

## 3. Add the public key to GitHub

Print the public key:

```bash
cat ~/.ssh/id_ed25519.pub
```

Copy the entire line, which will look similar to:

```
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI... euler
```

Then on GitHub:

1. Go to **Settings**
2. Click **SSH and GPG keys**
3. Click **New SSH key**
4. **Title:** cs579 Euler
5. **Key type:** Authentication key
6. **Key:** paste the full line
7. **Save**

## 4. Verify SSH authentication

Back on Euler, test the connection:

```bash
ssh -T git@github.com
```

Expected message:

```
Hi <username>! You've successfully authenticated, but GitHub does not provide shell access.
```

If you see this message, SSH is working correctly.

## 5. Make sure your repository uses SSH

Check the repository's remote URL:

```bash
git remote -v
```

If you see an HTTPS URL (`https://github.com/...`), switch it to SSH:

```bash
git remote set-url origin git@github.com:USERNAME/REPO.git
```

Example:

```bash
git remote set-url origin git@github.com:bbadger1/repo759.git
```

Verify the change:

```bash
git remote -v
```

You should now see `git@github.com:...` for both fetch and push.

## 6. Test Git commands

```bash
git pull
git push
```

You should no longer be prompted for a password or token.
