--- conda_build/post.py.orig	2024-09-03 18:55:54.000000000 -0600
+++ conda_build/post.py	2024-09-03 19:32:46.000000000 -0600
@@ -636,10 +636,11 @@
         if old.startswith("$ORIGIN"):
             new.append(old)
         elif old.startswith("/"):
-            # Test if this absolute path is outside of prefix. That is fatal.
+            # Test if this absolute path is outside of prefix. That is fatal (but we'll allow it- BSK!)
             rp = relpath(old, prefix)
             if rp.startswith(".." + os.sep):
-                print(f"Warning: rpath {old} is outside prefix {prefix} (removing it)")
+                print(f"Warning: external rpath {old}")
+                new.append(old)
             else:
                 rp = "$ORIGIN/" + relpath(old, origin)
                 if rp not in new:
