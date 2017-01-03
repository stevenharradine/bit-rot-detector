# bit-rot-detector
Detects if files within a file path have changed.

## Requirements
 * Redis

## Usage
### Build your index and hashes.
```
./build.sh {{ root_path }} {{ folder_name }} {{ options }}
```
where,
 * `root_path` - generally should be the root paths things mount too
 * `folder_name` - the drive name as it mounts to the system
 * `options` (enumeration)
  * `--verbose` (flag) - set this when running to get verbose feedback during execution (recommended for larger checks so you can see where you are at)

### Check your hashes
```
./check.sh {{ root_path }} {{ folder_name }} {{ options }}
```
