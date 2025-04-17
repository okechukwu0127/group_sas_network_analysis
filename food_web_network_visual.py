# Save this script as foodweb_visualization.py

import pandas as pd
import networkx as nx
import matplotlib.pyplot as plt

# Load the food web CSV
df = pd.read_csv('/Users/oeze/Downloads/network_project/foodweb-baywet.csv')  # Update with your actual path

# Create a directed graph (since food webs have direction)
G = nx.DiGraph()

# Add weighted edges from Source to Target
for _, row in df.iterrows():
    G.add_edge(row['Source'], row['Target'], weight=row['Weight'])

# Get edge weights as labels for display
edge_labels = nx.get_edge_attributes(G, 'weight')

# Draw the graph
pos = nx.spring_layout(G, k=0.4)  # Positions for layout
plt.figure(figsize=(12, 10))
nx.draw(G, pos, with_labels=True, node_color='lightgreen', node_size=800, font_size=8, arrows=True)
nx.draw_networkx_edge_labels(G, pos, edge_labels=edge_labels, font_size=7)

plt.title("Food Web Network Diagram (Directed with Weights)")
plt.show()

nx.write_gexf(G, "/Users/oeze/Downloads/network_project/foodweb_baywet.gexf")
