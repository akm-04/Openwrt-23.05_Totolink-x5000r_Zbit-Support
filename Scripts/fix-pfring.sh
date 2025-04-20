#!/bin/sh
cd openwrt
cat > feeds/packages/libs/libpfring/patches/009-fix-pf-ring-8.0.patch << 'EOF'
--- a/kernel/pf_ring.c  2021-08-11 14:41:00.000000000 +0600
+++ b/kernel/pf_ring.c  2024-06-25 15:02:21.534724969 +0600
@@ -5606,7 +5606,7 @@
 static int ring_bind(struct socket *sock, struct sockaddr *sa, int addr_len)
 {
   struct sock *sk = sock->sk;
-  char name[sizeof(sa->sa_data)+1];
+  char name[sizeof(sa->sa_data_min)+1];
 
   debug_printk(2, "ring_bind() called\n");
 
@@ -5620,7 +5620,7 @@
   if(sa->sa_data == NULL)
     return(-EINVAL);
 
-  memcpy(name, sa->sa_data, sizeof(sa->sa_data));
+  memcpy(name, sa->sa_data, sizeof(sa->sa_data_min));
 
   /* Add trailing zero if missing */
   name[sizeof(name)-1] = '\0';
EOF