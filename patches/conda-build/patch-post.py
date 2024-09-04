639c639
<             # Test if this absolute path is outside of prefix. That is fatal.
---
>             # Test if this absolute path is outside of prefix. That is fatal (but we'll allow it- BSK!)
642c642,643
<                 print(f"Warning: rpath {old} is outside prefix {prefix} (removing it)")
---
>                 print(f"Warning: rpath {old} is outside prefix {prefix} (but keeping it)")
>                 new.append(old)
