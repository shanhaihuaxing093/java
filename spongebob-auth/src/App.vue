<template>
  <router-view />
  <GlobalLoading />
  <ToastHost />
</template>

<script setup>
import GlobalLoading from './components/GlobalLoading.vue'
import ToastHost from './components/ToastHost.vue'
</script>
