# StumpWM Tomato

Advanced Pomodoro timer module for StumpWM

## Installation

```bash
cd ~/.stumpwm.d/modules/
git clone https://github.com/Junker/stumpwm-tomato tomato
```

```lisp
(stumpwm:add-to-load-path "~/.stumpwm.d/modules/tomato")
(load-module "tomato")
```

## Usage

```lisp
  (tomato:init)
  (setf stumpwm:*screen-mode-line-format* "%t")
```

### Commands

- **tomato-work** - start work
- **tomato-break** - start break
- **tomato-postpone** - postpone break
- **tomato-status** - show tomato status

### Parameters

- **tomato:\*short-break-period\*** - Short break in minutes after almost every work period.
- **tomato:\*long-break-period\*** - Long break in minutes after *max-tomatos* short breaks.
- **tomato:\*work-period\*** - Amount of time in minutes of working before taking a break.
- **tomato:\*postpone-period\*** - Amount of time in minutes to postpone the break.
- **tomato:\*max-tomatoes\*** - A long break will begin after *max-tomatos* tomatoes.

## Modeline

%t - tomato formatter

### Modeline mouse interaction

- **left button:** postpone break (when in break mode)
