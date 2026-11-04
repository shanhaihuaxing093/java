// 轻量 toast：发布/订阅总线，由 components/ToastHost.vue 订阅渲染
const listeners = new Set()

export const toastBus = {
  push(fn) {
    listeners.add(fn)
    return () => listeners.delete(fn)
  }
}

export function toast(msg, type = 'info') {
  listeners.forEach((fn) => {
    try {
      fn(msg, type)
    } catch {
      /* 单个订阅者异常不影响其他 */
    }
  })
}
