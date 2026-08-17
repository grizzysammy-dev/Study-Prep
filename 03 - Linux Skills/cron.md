---
tags: [jcu, module3, linux]
jqr: "Module 3 — schedule recurring jobs with cron: crontab -e/-l, the 5 time fields, @reboot, system cron dirs"
---

# cron

Running commands on a schedule. The whole skill is reading and writing the **5 time fields**, knowing `@reboot`, and remembering cron's minimal environment bites you with relative paths. As a defender, other people's crontabs are also a classic persistence hiding spot — know where they live.

## TL;DR
```bash
crontab -e        # EDIT your crontab
crontab -l        # LIST your cron jobs
crontab -r        # REMOVE your whole crontab (careful!)
```
```
* * * * *  command        # min(0-59) hour(0-23) dom(1-31) month(1-12) dow(0-7, 0&7=Sun)
0 2 * * *      /opt/backup.sh     # every day at 02:00
*/5 * * * *    /opt/check.sh      # every 5 minutes
30 8 * * 1-5   cmd                # 08:30 Mon–Fri
@reboot        /opt/startup.sh    # once at every boot
```
- **Use absolute paths** (`/usr/bin/python3`, not `python3`) — cron runs with a bare `$PATH`.

## Concept
`cron` is a daemon that wakes every minute and runs any job whose schedule matches the current time. Each **user** has their own crontab (`crontab -e`); the **system** also has crontabs in `/etc/` that add a *user* column. Jobs run **non-interactively** with a minimal environment — no `.bashrc`, no login `$PATH` — which is the source of most "works in my shell, not in cron" bugs.

## Managing your crontab
```bash
crontab -e        # EDIT your crontab (opens an editor)
crontab -l        # LIST your current cron jobs
crontab -r        # REMOVE your whole crontab (no confirmation — careful!)
sudo crontab -e -u www-data   # edit another user's crontab
```
→ `-e` edit, `-l` list, `-r` remove. `-r` nukes the lot with no prompt — `crontab -l > backup.cron` first if unsure.

## The 5 time fields
```
┌───────── minute        (0–59)
│ ┌─────── hour          (0–23)
│ │ ┌───── day of month  (1–31)
│ │ │ ┌─── month         (1–12)
│ │ │ │ ┌─ day of week   (0–7, both 0 and 7 = Sunday)
│ │ │ │ │
* * * * *  command-to-run
```
- `*` = "every." `,` = a list (`1,15`). `-` = a range (`1-5`). `/` = a step (`*/5` = every 5).

**Examples:**
```bash
0 2 * * *      /opt/backup.sh          # every day at 02:00
*/5 * * * *    /usr/local/bin/check.sh # every 5 minutes
0 */6 * * *    cmd                     # every 6 hours (00:00,06:00,12:00,18:00)
30 8 * * 1-5   cmd                     # 08:30, Monday–Friday (dow 1-5)
0 0 1 * *      cmd                     # midnight on the 1st of every month
@reboot        /opt/startup.sh         # run ONCE at every boot
@daily         cmd                     # shorthand: @hourly @daily @weekly @monthly @yearly
```
→ Read left-to-right: minute, hour, day-of-month, month, day-of-week. When both day-of-month *and* day-of-week are set, cron runs when **either** matches (a common surprise).

**"Run at boot" = `@reboot`** — put it as the whole schedule field. It fires once when cron starts after boot (not a real-time guarantee; for precise boot ordering a systemd unit/timer is better — see [Processes and systemd](Processes%20and%20systemd.md)).

## System-wide cron locations (not per-user)
- **`/etc/crontab`** and **`/etc/cron.d/*`** — system crontabs; these have an **extra 6th field = the user** to run as:
  ```
  0 3 * * * root /opt/job.sh
  ```
- **`/etc/cron.hourly/`, `/etc/cron.daily/`, `/etc/cron.weekly/`, `/etc/cron.monthly/`** — drop an executable **script** in (no time line needed; runs at that cadence).
> **User vs system field count:** user crontabs (`crontab -e`) have **5** fields; `/etc/crontab` and `/etc/cron.d/*` have **6** (the user column). Mixing them up is a frequent error.

## Exam tips & gotchas
- **Absolute paths + set your own env.** Cron's `$PATH` is bare — `python3` may not resolve; use `/usr/bin/python3`.
- **Capture output** or you'll never see errors: `... >> /var/log/myjob.log 2>&1`. Cron emails output by default, which usually goes nowhere on a lab box.
- **5 fields for user crontabs, 6 for `/etc/crontab` & `/etc/cron.d`** (the extra one is the run-as user).
- **`@reboot`** = run once at boot; the other `@` shorthands cover hourly→yearly.
- Day-of-month and day-of-week together = runs when **either** matches, not both.
- Times follow the **system timezone** — check with `timedatectl`.
- Defender's note: check `crontab -l` for every user and the `/etc/cron.*` dirs — cron is a favourite persistence mechanism.

## References
- `man 5 crontab` (the time-field format), `man 1 crontab` (the command)
- `man 8 cron`
- crontab.guru (schedule builder/tester): https://crontab.guru/

## Related
- [Processes and systemd](Processes%20and%20systemd.md)
- [Bash Scripting](../01%20-%20Fundamentals/Bash%20Scripting.md)
- [Logs and journalctl](Logs%20and%20journalctl.md)
- [Files Search and Permissions](Files%20Search%20and%20Permissions.md)
