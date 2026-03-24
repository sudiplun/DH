#!/bin/bash

# --------------------- CONFIGURE THESE ---------------------
input_file="./vmsForDatacenter_Name.csv"
output_file="vms.csv"

columns_to_remove=(
    "Managed By"
    "Cluster"
    "Fault Domain"
    "Active Memory"
    "DRAM Read Bandwidth"
    "PMem Read Bandwidth"
    "Guest OS"
    "Compatibility"
    "Reservation"
    "NICs"
    "Uptime"
    "IP Address"
    "VMware Tools Version Status"
    "DNS Name"
    "EVC CPU Mode"
    "EVC Graphics Mode (vSGA)"
    "UUID"
    "Notes"
    "Alarm Actions"
    "HA Protection"
    "Needs Consolidation"
    "VM Storage Policies Compliance"
    "Encryption"
    "TPM"
    "VBS"
    "Backup Status"
    "Last Backup"
)
# -----------------------------------------------------------

# Convert to lowercase for case-insensitive comparison
remove_lower=()
for col in "${columns_to_remove[@]}"; do
    remove_lower+=("$(echo "$col" | tr '[:upper:]' '[:lower:]')")
done

# Build awk condition: keep only if not in remove list
condition="1"  # start with true
for val in "${remove_lower[@]}"; do
    condition="$condition && tolower(\$i) != \"$val\""
done

# If nothing to remove
[ ${#remove_lower[@]} -eq 0 ] && { cp "$input_file" "$output_file"; echo "Nothing to remove."; exit 0; }

# Main awk (case-insensitive column removal)
awk -F',' -v OFS=',' "
NR==1 {
    out = \"\"
    delete keep_idx
    k = 1
    for(i=1; i<=NF; i++) {
        if ($condition) {
            if (out) out = out OFS
            out = out \$i
            keep_idx[k++] = i
        }
    }
    print out
    next
}
{
    out = \"\"
    for(i=1; i<k; i++) {
        if (out) out = out OFS
        out = out \$(keep_idx[i])
    }
    print out
}" "$input_file" > "$output_file"

echo "Done! Cleaned file saved as '$output_file'"
