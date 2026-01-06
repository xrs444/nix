function choose_nix_shell
    set shells qmk other
    echo "Select a shell:"
    for i in (seq (count $shells))
        echo "$i) $shells[$i]"
    end
    read -P "Enter number: " choice
    if test "$choice" -ge 1 -a "$choice" -le (count $shells)
        set shell_file $shells[$choice].nix
        echo "Launching nix-shell $shell_file..."
        nix-shell $shell_file
    else
        echo "Invalid choice."
    end
end

choose_nix_shell
