This is a demo to illustrate how to control the workload deploy to target node in different node pools.

In this demo there are 3 worker node pools. All of them has different labels:<br>
<table border="1">
<tr>
    <th>label</th>
    <th>purpose</th>
    <th>pricing</th>
</tr>
<tr>
    <td>general</td>
    <td>General Purpose VM</td>
    <td><a href="https://azure.microsoft.com/en-us/pricing/details/virtual-machines/linux/#pricing">Pricing of general purpose VM</a></td>    
</tr>
<tr>
    <td>compute</td>
    <td>Compute optimized VM</td>
    <td><a href="https://azure.microsoft.com/en-us/pricing/details/virtual-machines/linux/#pricing">Pricing of compute optimized VM</a></td>    
</tr>
<tr>
    <td>spot</td>
    <td>Spot VM of general purpose VM</td>
    <td><a href="https://azure.microsoft.com/en-us/pricing/spot-advisor/">Pricing of Spot VM</a></td>
</tr>
</table>
<br>
We will demo the use of nodeSelector and taints + tolerations