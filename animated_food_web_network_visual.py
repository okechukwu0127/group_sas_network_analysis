
import pandas as pd
import networkx as nx
import plotly.graph_objects as go

# Load your dataset
df = pd.read_csv('/Users/oeze/Downloads/network_project/foodweb-baywet.csv')


# Create a directed graph
G = nx.DiGraph()

# Add edges and weights (convert node labels to str)
for _, row in df.iterrows():
    G.add_edge(str(row['Source']), str(row['Target']), weight=row['Weight'])

# Layout for nodes
pos = nx.spring_layout(G, seed=42)

# Edge lines
edge_x = []
edge_y = []
edge_labels = []
edge_label_x = []
edge_label_y = []

for src, tgt in G.edges():
    x0, y0 = pos[src]
    x1, y1 = pos[tgt]

    edge_x += [x0, x1, None]
    edge_y += [y0, y1, None]

    weight = G[src][tgt].get('weight', 0.0)* 1000
    print(f"Edge {src} → {tgt} = {weight}")  # Debug line to confirm correct lookup
    mx, my = (x0 + x1) / 2, (y0 + y1) / 2
    edge_label_x.append(mx)
    edge_label_y.append(my)
    edge_labels.append(f"{weight:.2f}")

# Node positions
node_x = []
node_y = []
node_text = []

for node in G.nodes():
    x, y = pos[node]
    node_x.append(x)
    node_y.append(y)

    in_weight = sum(G[pre][node]['weight'] for pre in G.predecessors(node))
    out_weight = sum(G[node][nxt]['weight'] for nxt in G.successors(node))
    node_text.append(f"{node}<br>In: {in_weight:.2f} | Out: {out_weight:.2f}")

# Create edge trace
edge_trace = go.Scatter(
    x=edge_x,
    y=edge_y,
    line=dict(width=1, color='gray'),
    hoverinfo='none',
    mode='lines'
)

# Edge labels
edge_label_trace = go.Scatter(
    x=edge_label_x,
    y=edge_label_y,
    mode='text',
    text=edge_labels,
    textfont=dict(color='red', size=10),
    hoverinfo='none'
)

# Node trace
node_trace = go.Scatter(
    x=node_x,
    y=node_y,
    mode='markers+text',
    textposition='top center',
    hoverinfo='text',
    text=[str(node) for node in G.nodes()],
    marker=dict(
        showscale=True,
        colorscale='YlGnBu',
        color=[G.degree(n) for n in G.nodes()],
        size=12,
        colorbar=dict(
            thickness=15,
            title=dict(text='Node Degree', side='right'),
            xanchor='left',
        )
    ),
    hovertext=node_text
)

# Final layout
fig = go.Figure(
    data=[edge_trace, edge_label_trace, node_trace],
    layout=go.Layout(
        title='Interactive Network with Edge Weights',
        showlegend=False,
        hovermode='closest',
        margin=dict(b=20, l=5, r=5, t=40),
        xaxis=dict(showgrid=False, zeroline=False),
        yaxis=dict(showgrid=False, zeroline=False)
    )
)

fig.show()
