--- ./conda_build/post.py.orig	2024-07-31 18:11:15.000000000 -0600
+++ ./conda_build/post.py	2024-09-07 09:05:50.000000000 -0600
@@ -576,7 +576,7 @@
 """
 
 
-def mk_relative_linux(f, prefix, rpaths=("lib",), method=None):
+def mk_relative_linux(f, prefix, rpaths=("lib",), host_runpath_whitelist=[], method=None):
     "Respects the original values and converts abs to $ORIGIN-relative"
 
     elf = join(prefix, f)
@@ -624,10 +624,11 @@
                     f"WARNING :: get_rpaths_raw({elf!r}) with LIEF failed: {e}, will proceed with patchelf"
                 )
             method = "patchelf"
-        if existing_pe and existing_pe != existing2:
-            print(
-                f"WARNING :: get_rpaths_raw()={existing2} and patchelf={existing_pe} disagree for {elf} :: "
-            )
+        # # not an issue when we hijack runpath_whitelist
+        # if existing_pe and existing_pe != existing2:
+        #     print(
+        #         f"WARNING :: get_rpaths_raw()={existing2} and patchelf={existing_pe} disagree for {elf} :: "
+        #     )
         # Use LIEF if method is LIEF to get the initial value?
         if method == "LIEF":
             existing = existing2
@@ -636,10 +637,17 @@
         if old.startswith("$ORIGIN"):
             new.append(old)
         elif old.startswith("/"):
-            # Test if this absolute path is outside of prefix. That is fatal.
+            # Test if this absolute path is outside of prefix.
             rp = relpath(old, prefix)
             if rp.startswith(".." + os.sep):
-                print(f"Warning: rpath {old} is outside prefix {prefix} (removing it)")
+                # allow it only if in host_runpath_whitelist.
+                # BSK - nonstandard behavior to allow packages that depend on host libraries,
+                #       e.g. host-mpi on Derecho.  Usual conda-build would strip this path regardless
+                if host_runpath_whitelist and any(fnmatch(old, w) for w in host_runpath_whitelist):
+                    print(f"External rpath {old} allowed (found in host_runpath_whitelist)")
+                    new.append(old)
+                else:
+                    print(f"Warning: rpath {old} is outside prefix {prefix} (removing it)")
             else:
                 rp = "$ORIGIN/" + relpath(old, origin)
                 if rp not in new:
@@ -1622,6 +1630,7 @@
             f,
             host_prefix,
             rpaths=rpaths,
+            host_runpath_whitelist=m.get_value("build/host_runpath_whitelist", []),
             method=m.get_value("build/rpaths_patcher", None),
         )
     elif codefile == machofile:
