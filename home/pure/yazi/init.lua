require('full-border'):setup {
  type = ui.Border.ROUNDED
}

require('yatline'):setup()

require('starship'):setup()

require('git'):setup {
  -- Order of status signs showing in the linemode
  order = 1500
}

