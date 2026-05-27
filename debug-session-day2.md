# Debug Session Day 2

## Scenario

Verify MVP của Day 2: dùng Kubernetes MCP server (kết nối qua kubeconfig read-only) để truy vấn cluster local `insighthub-lab` và kiểm tra trạng thái workload trong namespace `insighthub`.

## Prompt

> Dùng Kubernetes MCP kiểm tra namespace insighthub có pod nào đang chạy

## MCP servers used

- kubernetes

## Result

| Field | Value |
|---|---|
| Pod name | `nginx-7f754fd6cd-nnnrs` |
| Namespace | `insighthub` |
| Status | `Running` (1/1 ready, 0 restarts, age 12m) |
| Node | `insighthub-lab-control-plane` |
| Pod IP | `10.244.0.5` |
| Labels | `app=nginx`, `pod-template-hash=7f754fd6cd` |

**Log summary:** nginx 1.27.5 khởi động bình thường lúc `2026/05/27 08:06:13` — entrypoint scripts (`10-listen-on-ipv6-by-default`, `20-envsubst-on-templates`, `30-tune-worker-processes`) chạy xong, master process spawn 16 worker (PID 33–48) bằng event method `epoll`. Không có error/warning, không có request log → pod ở idle state, không có traffic.

## Conclusion

Day 2 MCP MVP đã connect được tới local cluster (`insighthub-lab`, kind) bằng kubeconfig read-only: Kubernetes MCP server liệt kê pod và đọc log thành công mà không cần thao tác `kubectl` thủ công. Cluster hiện chỉ có pod nginx test — chưa deploy stack thật của InsightHub (api/web/worker/redis/postgres) lên cluster.
