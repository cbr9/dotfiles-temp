{...}: {
  services.betterlockscreen = {
    enable = true;
    inactiveInterval = 5;
  };
  xdg.configFile."betterlockscreenrc".text = ''
    # ~/.config/betterlockscreenrc

    # default options
    display_on=0
    span_image=false
    lock_timeout=300
    fx_list=(dim blur dimblur pixel dimpixel color)
    dim_level=40
    blur_level=1
    pixel_scale=10,1000
    solid_color=333333
    wallpaper_cmd="feh --bg-fill"
    quiet=false

    # default theme
    loginbox=00000066
    loginshadow=00000000
    locktext="Type password to unlock..."
    font="sans-serif"
    ringcolor=ffffffff
    insidecolor=00000000
    separatorcolor=00000000
    ringvercolor=ffffffff
    insidevercolor=00000000
    ringwrongcolor=ffffffff
    insidewrongcolor=d23c3dff
    timecolor=ffffffff
    time_format="%H:%M:%S"
    greetercolor=ffffffff
    layoutcolor=ffffffff
    keyhlcolor=d23c3dff
    bshlcolor=d23c3dff
    veriftext="Verifying..."
    verifcolor=ffffffff
    wrongtext="Failure!"
    wrongcolor=d23c3dff
    modifcolor=d23c3dff
    bgcolor=000000ff


    #
    # expert options (change at own risk!)
    #

    i3lockcolor_bin="/run/wrappers/bin/i3lock"      # Manually set command for i3lock-color
    # suspend_command="systemctl suspend" # Manually change action e.g. hibernate/suspend-command

    # i3lock-color - custom arguments
    # lockargs=() 						  # overwriting default "(-n)"
    # lockargs+=(--ignore-empty-password) # appending new argument
  '';
  services.caffeine.enable = true;
}
