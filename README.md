# arm-pops-daq

Add to root crontab
```
@reboot /sbin/runuser -l puser -c "tmux new-session -d -s pops /home/puser/startup.sh" > cron.log 2>&1
```

Create startup.sh
```bash
cd /home/puser/opt/arm-pops-daq/src  
/home/puser/.juliaup/bin/julia -i main.jl 
```
