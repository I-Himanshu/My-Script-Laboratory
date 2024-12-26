# QuantumShell Dev ZSH Theme

setopt PROMPT_SUBST
autoload -U colors && colors

# Git config and styling
ZSH_THEME_GIT_PROMPT_PREFIX="%{$fg[cyan]%}("
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_DIRTY="%{$fg[red]%}*%{$fg[cyan]%})%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_CLEAN="%{$fg[cyan]%})"

# Enhanced Git information with improved visibility
function git_super_status() {
    if git rev-parse --git-dir > /dev/null 2>&1; then
        # Basic info
        local branch=$(git symbolic-ref HEAD 2>/dev/null | cut -d'/' -f3-)
        local staged=$(git diff --cached --numstat | wc -l | tr -d ' ')
        local unstaged=$(git diff --numstat | wc -l | tr -d ' ')
        local untracked=$(git ls-files --others --exclude-standard | wc -l | tr -d ' ')
        local stashes=$(git stash list | wc -l | tr -d ' ')
        
        # Get commit status with improved error handling
        local ahead=$(git rev-list --count @{u}.. 2>/dev/null || echo "0")
        local behind=$(git rev-list --count ..@{u} 2>/dev/null || echo "0")
        
        # Enhanced Git state detection
        local state=""
        if [[ -d .git/rebase-merge ]]; then
            state="|REBASE"
        elif [[ -f .git/MERGE_HEAD ]]; then
            state="|MERGE"
        elif [[ -f .git/CHERRY_PICK_HEAD ]]; then
            state="|CHERRY"
        elif [[ -f .git/REVERT_HEAD ]]; then
            state="|REVERT"
        elif [[ -f .git/BISECT_LOG ]]; then
            state="|BISECT"
        fi

        # Enhanced last commit info with author
        local last_commit=$(git log -1 --pretty=format:"%h [%cr by %cn]" 2>/dev/null)
        
        # Calculate days since last commit
        local days_since_commit=$(git log -1 --format="%cr" 2>/dev/null | grep -o '[0-9]\+' | head -n1)
        local commit_age=""
        if [[ $days_since_commit -gt 7 ]]; then
            commit_age="%{$fg[red]%}⚠️ Old%{$reset_color%}"
        fi
        
        # Build status string with enhanced emojis/symbols
        echo -n "%{$fg[cyan]%}ⓖ %{$fg_bold[magenta]%}$branch%{$reset_color%}"
        [[ $staged -gt 0 ]] && echo -n " %{$fg[green]%}⊕$staged%{$reset_color%}"
        [[ $unstaged -gt 0 ]] && echo -n " %{$fg[red]%}⊗$unstaged%{$reset_color%}"
        [[ $untracked -gt 0 ]] && echo -n " %{$fg[yellow]%}⊙$untracked%{$reset_color%}"
        [[ $stashes -gt 0 ]] && echo -n " %{$fg[blue]%}⚑$stashes%{$reset_color%}"
        [[ $ahead -gt 0 ]] && echo -n " %{$fg[green]%}↑$ahead%{$reset_color%}"
        [[ $behind -gt 0 ]] && echo -n " %{$fg[red]%}↓$behind%{$reset_color%}"
        [[ -n $state ]] && echo -n " %{$fg[red]%}$state%{$reset_color%}"
        echo -n " %{$fg[gray]%}$last_commit%{$reset_color%}"
        [[ -n $commit_age ]] && echo -n " $commit_age"
    fi
}

# Enhanced developer environment detector
function dev_env_info() {
    local info=""
    
    # Node.js with package version
    if [[ -f "package.json" ]]; then
        local pkg_version=$(cat package.json | grep '"version"' | head -1 | awk -F: '{ print $2 }' | sed 's/[",]//g' | tr -d '[[:space:]]')
        info+="%{$fg[green]%}⬡ $(node -v 2>/dev/null)($pkg_version)%{$reset_color%} "
        [[ -f "yarn.lock" ]] && info+="%{$fg[blue]%}YARN%{$reset_color%} "
        [[ -f "pnpm-lock.yaml" ]] && info+="%{$fg[yellow]%}PNPM%{$reset_color%} "
        
        # Check for outdated dependencies
        if [[ -n $(find "package.json" -mtime +30) ]]; then
            info+="%{$fg[yellow]%}📦?%{$reset_color%} "
        fi
    fi
    
    # Python with virtualenv and requirements status
    if [[ -f "requirements.txt" || -f "pyproject.toml" ]]; then
        info+="%{$fg[blue]%}🐍 $(python -V 2>&1 | cut -d' ' -f2)%{$reset_color%} "
        [[ -n "$VIRTUAL_ENV" ]] && info+="%{$fg[cyan]%}(${VIRTUAL_ENV:t})%{$reset_color%} "
        
        # Check requirements.txt age
        if [[ -f "requirements.txt" && -n $(find "requirements.txt" -mtime +30) ]]; then
            info+="%{$fg[yellow]%}📦?%{$reset_color%} "
        fi
    fi
    
    # Docker with container status
    if [[ -f "docker-compose.yml" || -f "docker-compose.yaml" ]]; then
        local running_containers=$(docker ps -q 2>/dev/null | wc -l | tr -d ' ')
        info+="%{$fg[blue]%}🐋($running_containers)%{$reset_color%} "
    fi
    
    # Rust
    if [[ -f "Cargo.toml" ]]; then
        info+="%{$fg[red]%}🦀 $(rustc --version | cut -d' ' -f2)%{$reset_color%} "
    fi
    
    # Go
    if [[ -f "go.mod" ]]; then
        info+="%{$fg[cyan]%}🐹 $(go version | cut -d' ' -f3 | sed 's/go//')%{$reset_color%} "
    fi
    
    echo $info
}

# Enhanced system status with more metrics
function system_status() {
    local statuss=""
    
    # RAM usage with threshold alerts
    local ram_usage=$(free -m | awk 'NR==2{printf "%.1f%%", $3*100/$2 }')
    if [[ ${ram_usage%.*} -gt 90 ]]; then
        statuss+="%{$fg_bold[red]%}RAM:$ram_usage%{$reset_color%} "
    elif [[ ${ram_usage%.*} -gt 80 ]]; then
        statuss+="%{$fg[red]%}RAM:$ram_usage%{$reset_color%} "
    elif [[ ${ram_usage%.*} -gt 70 ]]; then
        statuss+="%{$fg[yellow]%}RAM:$ram_usage%{$reset_color%} "
    fi
    
    # Load average with smart thresholds
    local cpu_cores=$(nproc)
    local load=$(uptime | awk '{print $(NF-2)}' | tr -d ',')
    if (( $(echo "$load > $cpu_cores" | bc -l) )); then
        statuss+="%{$fg[red]%}LOAD:$load%{$reset_color%} "
    elif (( $(echo "$load > $cpu_cores/2" | bc -l) )); then
        statuss+="%{$fg[yellow]%}LOAD:$load%{$reset_color%} "
    fi
    
    # Disk space check for root partition
    local disk_usage=$(df -h / | awk 'NR==2 {print $5}' | tr -d '%')
    if [[ $disk_usage -gt 90 ]]; then
        statuss+="%{$fg_bold[red]%}DISK:$disk_usage%%%{$reset_color%} "
    elif [[ $disk_usage -gt 80 ]]; then
        statuss+="%{$fg[yellow]%}DISK:$disk_usage%%%{$reset_color%} "
    fi
    
    echo $statuss
}

# Enhanced timer for long-running commands
function preexec() {
    timer=$(($(date +%s%0N)/1000000))
}

function precmd() {
    if [ $timer ]; then
        now=$(($(date +%s%0N)/1000000))
        elapsed=$(($now-$timer))
        
        # Enhanced time display with units
        if [[ $elapsed -gt 60000 ]]; then
            export RPROMPT="%{$fg[red]%}$(($elapsed/60000))m$(($elapsed%60000/1000))s%{$reset_color%}"
        elif [[ $elapsed -gt 5000 ]]; then
            export RPROMPT="%{$fg[yellow]%}$(($elapsed/1000))s%{$reset_color%}"
        else
            export RPROMPT=""
        fi
        unset timer
    fi
}

# Time-based color schemes
function get_time_color() {
    local hour=$(date +%H)
    if [[ $hour -ge 6 && $hour -lt 12 ]]; then
        echo "cyan"    # Morning
    elif [[ $hour -ge 12 && $hour -lt 18 ]]; then
        echo "yellow"  # Afternoon
    elif [[ $hour -ge 18 && $hour -lt 22 ]]; then
        echo "magenta" # Evening
    else
        echo "blue"    # Night
    fi
}

# Main prompt construction with time-based colors
PROMPT=$'
%{$fg_bold[$(get_time_color)]%}┌─[%{$fg_bold[white]%}%n%{$fg[magenta]%}@%{$fg[white]%}%m%{$fg_bold[$(get_time_color)]%}]%{$reset_color%} %{$fg[yellow]%}%~%{$reset_color%} $(git_super_status)
%{$fg_bold[$(get_time_color)]%}└─▶ %{$reset_color%}'

# Right prompt with dev environment and system status
RPROMPT='$(dev_env_info)$(system_status)'

# Exit code indicator with status
PROMPT2="%{$fg_bold[cyan]%}%_→%{$reset_color%} "

# Selection prompt
PROMPT3="%{$fg_bold[cyan]%}?→%{$reset_color%} "

# Execution trace prompt
PROMPT4="%{$fg_bold[cyan]%}+→%{$reset_color%} "
