config.load_autoconfig(False) # ignore GUI settings

config.bind('cs', 'config-source')

config.bind('zi', 'zoom-in')
config.bind('zo', 'zoom-out')

config.bind('si', 'hint images download')

config.bind('<Ctrl-p>', 'completion-item-focus --history prev', mode='command')
config.bind('<Ctrl-n>', 'completion-item-focus --history next', mode='command')

config.bind('gp', 'open -p')
