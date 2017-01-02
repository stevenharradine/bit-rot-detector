# bit-rot-detector
Detects if files within a file path have changed.

## Usage
### Build your index and hashes.
```
./build.sh {{ root_path }} {{ folder_name }}
```
where,
 * `root_path` - generally should be the root paths things mount too
 * `folder_name` - the drive name as it mounts to the system

### Check your hashes
```
./check.sh {{ root_path }} {{ folder_name }}
```
