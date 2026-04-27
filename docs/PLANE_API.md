# Plane API Integration Guide

## Base URL
```
http://localhost/api/v1/workspaces/{workspace}/projects/{project}/
```

## Headers
```python
headers = {
    "x-api-key": PLANE_API_KEY,
    "Content-Type": "application/json"
}
```

## Common Endpoints

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/issues/` | GET | List issues |
| `/issues/{id}/` | PATCH | Update issue (name, state, labels) |
| `/issues/{id}/` | GET | Get single issue |
| `/labels/` | GET | List labels |
| `/labels/` | POST | Create label |
| `/cycles/` | GET | List cycles |
| `/cycles/{id}/cycle-issues/` | POST | Add issue to cycle |
| `/modules/` | GET | List modules |
| `/modules/` | POST | Create module |

**Note:** Views cannot be created via API - must use Plane UI: Project → Views → New View

This is a known gap - see [GitHub Issue #8816](https://github.com/makeplane/plane/issues/8816)

## Examples

### List issues
```python
response = requests.get(
    f"{PLANE_URL}/api/v1/workspaces/{workspace}/projects/{project}/issues/",
    headers=headers, verify=False
)
issues = response.json().get("results", [])
```

### Update issue
```python
requests.patch(
    f"{PLANE_URL}/api/v1/workspaces/{workspace}/projects/{project}/issues/{id}/",
    json={
        "name": "New task name",
        "state": "todo_state_id",
        "labels": ["label_id1", "label_id2"]
    },
    headers=headers, verify=False
)
```

### Create label
```python
requests.post(
    f"{PLANE_URL}/api/v1/workspaces/{workspace}/projects/{project}/labels/",
    json={"name": "kafka", "color": "#a855f7"},
    headers=headers, verify=False
)
```

### Add issue to cycle
```python
requests.post(
    f"{PLANE_URL}/api/v1/workspaces/{workspace}/projects/{project}/cycles/{cycle_id}/cycle-issues/",
    json={"issues": ["issue_id"]},
    headers=headers, verify=False
)
```

## Known Issues

- `VERIFY_SSL = False` required for localhost
- Views must be created manually in Plane UI
- Label IDs are UUIDs - fetch from `/labels/` endpoint first