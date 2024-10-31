import requests
from typing import List, Dict, Optional
from dataclasses import dataclass, asdict
from stacks_lib import StacksClient  # Hypothetical Stacks blockchain interaction library

@dataclass
class ConservationProject:
    """
    Represents a conservation project with blockchain-backed transparency
    """
    name: str
    description: str
    target_funding: float
    current_funding: float = 0.0
    status: str = 'PROPOSED'
    impact_metrics: List[Dict[str, Any]] = None

class EnvironmentalConservationTracker:
    def __init__(self, stacks_node_url: str, contract_address: str):
        """
        Initialize blockchain interaction for conservation projects
        
        :param stacks_node_url: URL of Stacks blockchain node
        :param contract_address: Deployed smart contract address
        """
        self.client = StacksClient(stacks_node_url)
        self.contract_address = contract_address
    
    def create_conservation_project(self, project: ConservationProject) -> Dict:
        """
        Create a new conservation project on blockchain
        
        :param project: Project details
        :return: Transaction response
        """
        try:
            tx_params = {
                'contract_address': self.contract_address,
                'method': 'create-conservation-project',
                'args': [
                    project.name,
                    project.description,
                    project.target_funding
                ]
            }
            return self.client.execute_contract_call(tx_params)
        except Exception as e:
            # Comprehensive error handling
            print(f"Error creating project: {e}")
            return None
    
    def contribute_to_project(self, project_id: int, amount: float) -> Dict:
        """
        Contribute funds to a specific conservation project
        
        :param project_id: Unique project identifier
        :param amount: Contribution amount
        :return: Transaction response
        """
        try:
            tx_params = {
                'contract_address': self.contract_address,
                'method': 'contribute-to-project',
                'args': [project_id, amount]
            }
            return self.client.execute_contract_call(tx_params)
        except Exception as e:
            print(f"Contribution error: {e}")
            return None
    
    def add_impact_metrics(self, project_id: int, metrics: List[Dict]) -> Dict:
        """
        Add post-project impact metrics
        
        :param project_id: Unique project identifier
        :param metrics: List of impact metrics
        :return: Transaction response
        """
        try:
            tx_params = {
                'contract_address': self.contract_address,
                'method': 'add-impact-metrics',
                'args': [project_id, metrics]
            }
            return self.client.execute_contract_call(tx_params)
        except Exception as e:
            print(f"Metrics addition error: {e}")
            return None
    
    def get_project_details(self, project_id: int) -> Optional[Dict]:
        """
        Retrieve project details from blockchain
        
        :param project_id: Unique project identifier
        :return: Project details or None
        """
        try:
            return self.client.read_contract_data(
                self.contract_address, 
                'get-project-details', 
                [project_id]
            )
        except Exception as e:
            print(f"Project retrieval error: {e}")
            return None

# Example Usage
def main():
    tracker = EnvironmentalConservationTracker(
        stacks_node_url='https://stacks-node.example.com',
        contract_address='ST1234...'
    )
    
    # Create a reforestation project
    reforestation_project = ConservationProject(
        name="Amazon Rainforest Restoration",
        description="Large-scale reforestation in Brazil's Amazon region",
        target_funding=500000.00
    )
    
    # Create project on blockchain
    project_response = tracker.create_conservation_project(reforestation_project)
    
    if project_response:
        print("Project created successfully!")
        print(f"Project ID: {project_response['project_id']}")

if __name__ == "__main__":
    main()