import asyncio
from typing import List, Dict, Optional
from dataclasses import dataclass, field
from enum import Enum, auto
import logging
from decimal import Decimal

class ProjectStatus(Enum):
    PROPOSED = auto()
    VOTING = auto()
    APPROVED = auto()
    FUNDING = auto()
    ACTIVE = auto()
    COMPLETED = auto()
    CLOSED = auto()

@dataclass
class Milestone:
    description: str
    funding_percentage: float
    is_completed: bool = False
    completion_date: Optional[datetime] = None

@dataclass
class ImpactMetric:
    metric_name: str
    value: float
    validator_approvals: List[str] = field(default_factory=list)

@dataclass
class ConservationProject:
    """
    Enhanced Conservation Project with Advanced Governance
    """
    name: str
    description: str
    target_funding: Decimal
    current_funding: Decimal = Decimal('0.00')
    status: ProjectStatus = ProjectStatus.PROPOSED
    owner: str = ''
    validators: List[str] = field(default_factory=list)
    voting_period: Optional[Tuple[datetime, datetime]] = None
    milestones: List[Milestone] = field(default_factory=list)
    impact_metrics: List[ImpactMetric] = field(default_factory=list)

class AdvancedConservationTracker:
    """
    Enhanced Blockchain-Based Conservation Project Management
    """
    def __init__(self, blockchain_client, validator_registry):
        """
        Initialize advanced tracking system
        
        :param blockchain_client: Blockchain interaction client
        :param validator_registry: External validator verification system
        """
        self.blockchain_client = blockchain_client
        self.validator_registry = validator_registry
        self.logger = logging.getLogger(self.__class__.__name__)
    
    async def create_conservation_project(
        self, 
        project: ConservationProject, 
        proposed_validators: List[str]
    ) -> Dict:
        """
        Create a new conservation project with advanced governance
        
        :param project: Project details
        :param proposed_validators: List of validator addresses
        :return: Project creation transaction response
        """
        try:
            # Validate proposed validators
            validated_validators = await self._validate_validators(proposed_validators)
            
            # Prepare blockchain transaction
            tx_params = {
                'method': 'create-conservation-project',
                'args': [
                    project.name,
                    project.description,
                    int(project.target_funding * 100),  # Convert to cents
                    validated_validators
                ]
            }
            
            # Execute blockchain transaction
            response = await self.blockchain_client.execute_contract_call(tx_params)
            
            # Log project creation
            self.logger.info(f"Project created: {project.name}")
            
            return response
        
        except Exception as e:
            self.logger.error(f"Project creation failed: {e}")
            raise
    
    async def _validate_validators(self, proposed_validators: List[str]) -> List[str]:
        """
        Validate and verify proposed project validators
        
        :param proposed_validators: List of potential validator addresses
        :return: Verified validator list
        """
        verified_validators = []
        
        for validator in proposed_validators:
            # Check validator reputation and credentials
            validator_info = await self.validator_registry.get_validator_details(validator)
            
            if validator_info and validator_info['reputation_score'] >= 75:
                verified_validators.append(validator)
        
        if len(verified_validators) < 2:
            raise ValueError("Insufficient qualified validators")
        
        return verified_validators
    
    async def add_project_milestones(
        self, 
        project_id: int, 
        milestones: List[Milestone]
    ) -> Dict:
        """
        Add and validate project milestones
        
        :param project_id: Unique project identifier
        :param milestones: List of project milestones
        :return: Milestone addition transaction response
        """
        try:
            # Validate milestone percentages
            total_percentage = sum(m.funding_percentage for m in milestones)
            if total_percentage != 100:
                raise ValueError("Milestone percentages must total 100%")
            
            # Prepare milestone data for blockchain
            milestone_data = [
                {
                    'description': m.description, 
                    'funding_percentage': int(m.funding_percentage)
                } 
                for m in milestones
            ]
            
            tx_params = {
                'method': 'add-project-milestones',
                'args': [project_id, milestone_data]
            }
            
            response = await self.blockchain_client.execute_contract_call(tx_params)
            
            self.logger.info(f"Milestones added to project {project_id}")
            return response
        
        except Exception as e:
            self.logger.error(f"Milestone addition failed: {e}")
            raise
    
    async def validate_project_impact(
        self, 
        project_id: int, 
        impact_metrics: List[ImpactMetric]
    ) -> Dict:
        """
        Validate project impact metrics through multi-validator consensus
        
        :param project_id: Unique project identifier
        :param impact_metrics: List of impact metrics to validate
        :return: Impact validation transaction response
        """
        try:
            # Fetch project validators
            project_details = await self.blockchain_client.get_project_details(project_id)
            project_validators = project_details.get('validators', [])
            
            # Prepare validated metrics
            validated_metrics = []
            for metric in impact_metrics:
                # Simulate validator voting process
                metric_validators = await self._collect_validator_approvals(
                    project_validators, 
                    project_id, 
                    metric
                )
                
                validated_metrics.append({
                    'metric_name': metric.metric_name,
                    'value': int(metric.value * 100),  # Convert to fixed-point
                    'validator_approvals': metric_validators
                })
            
            tx_params = {
                'method': 'add-impact-metrics',
                'args': [project_id, validated_metrics]
            }
            
            response = await self.blockchain_client.execute_contract_call(tx_params)
            
            self.logger.info(f"Impact metrics validated for project {project_id}")